-- lua/invoke_nvim/introspector.lua
-- Uses Python introspection to discover tasks from tasks.py files

local M = {}

--- Get tasks using Python introspection
-- @return table List of task tables with detailed information
function M.get_tasks_via_introspection()
  local detector = require("invoke_nvim.detector")
  
  -- Check if we should allow operations
  if not detector.should_allow_operations() then
    return {}
  end
  
  local tasks_file = vim.fn.getcwd() .. "/tasks.py"
  if vim.fn.filereadable(tasks_file) ~= 1 then
    return {}
  end
  
  -- Python script to introspect tasks.py
  local python_script = [[
import sys
import os
import inspect
import importlib.util
from pathlib import Path

def introspect_tasks(tasks_file_path):
    """Introspect tasks.py file to discover tasks."""
    try:
        # Load the tasks module
        spec = importlib.util.spec_from_file_location("tasks", tasks_file_path)
        if not spec or not spec.loader:
            return []
            
        tasks_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(tasks_module)
        
        tasks = []
        
        # Find all task functions
        for name, obj in inspect.getmembers(tasks_module):
            # Check if it's a callable and has the @task decorator
            if callable(obj) and hasattr(obj, '__wrapped__'):
                # This is likely a decorated task
                task_info = {
                    'name': name,
                    'doc': inspect.getdoc(obj) or '',
                    'signature': str(inspect.signature(obj)),
                    'source_file': tasks_file_path,
                    'line_number': inspect.getsourcelines(obj)[1] if inspect.getsourcelines(obj) else None
                }
                tasks.append(task_info)
            elif callable(obj) and inspect.isfunction(obj):
                # Check if it's a regular function that might be a task
                # Look for common task patterns
                source_lines = inspect.getsourcelines(obj)[0] if inspect.getsourcelines(obj) else []
                if source_lines and any('@task' in line for line in source_lines):
                    task_info = {
                        'name': name,
                        'doc': inspect.getdoc(obj) or '',
                        'signature': str(inspect.signature(obj)),
                        'source_file': tasks_file_path,
                        'line_number': inspect.getsourcelines(obj)[1] if inspect.getsourcelines(obj) else None
                    }
                    tasks.append(task_info)
        
        return tasks
        
    except Exception as e:
        print(f"Error introspecting tasks: {e}", file=sys.stderr)
        return []

if __name__ == "__main__":
    tasks_file = sys.argv[1] if len(sys.argv) > 1 else "tasks.py"
    tasks = introspect_tasks(tasks_file)
    
    # Output as JSON-like format for easy parsing
    for task in tasks:
        print(f"TASK:{task['name']}")
        print(f"DOC:{task['doc']}")
        print(f"SIG:{task['signature']}")
        print(f"FILE:{task['source_file']}")
        print(f"LINE:{task['line_number'] or 'unknown'}")
        print("---")
]]

  -- Write Python script to temporary file
  local temp_script = vim.fn.tempname() .. "_introspect.py"
  local file = io.open(temp_script, "w")
  if not file then
    vim.notify("Failed to create temporary Python script", vim.log.levels.ERROR)
    return {}
  end
  
  file:write(python_script)
  file:close()
  
  -- Execute Python script
  local handle = io.popen(string.format("python3 %s %s 2>/dev/null", temp_script, tasks_file))
  if not handle then
    os.remove(temp_script)
    return {}
  end
  
  local result = handle:read("*a")
  handle:close()
  os.remove(temp_script)
  
  -- Parse the output
  local tasks = {}
  local current_task = {}
  
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^TASK:") then
      -- Save previous task if exists
      if current_task.name then
        table.insert(tasks, current_task)
      end
      -- Start new task
      current_task = { name = line:sub(6) }
    elseif line:match("^DOC:") then
      current_task.doc = line:sub(5)
    elseif line:match("^SIG:") then
      current_task.signature = line:sub(5)
    elseif line:match("^FILE:") then
      current_task.source_file = line:sub(6)
    elseif line:match("^LINE:") then
      current_task.line_number = line:sub(6)
    end
  end
  
  -- Add the last task
  if current_task.name then
    table.insert(tasks, current_task)
  end
  
  return tasks
end

--- Get detailed task information including source code
-- @param task_name string Name of the task
-- @return table Detailed task information
function M.get_task_details(task_name)
  local tasks = M.get_tasks_via_introspection()
  
  for _, task in ipairs(tasks) do
    if task.name == task_name then
      -- Get source code if available
      if task.line_number and task.source_file then
        local file = io.open(task.source_file, "r")
        if file then
          local lines = {}
          for line in file:lines() do
            table.insert(lines, line)
          end
          file:close()
          
          -- Extract function source code
          local start_line = tonumber(task.line_number)
          if start_line then
            local source_lines = {}
            local in_function = false
            local indent_level = nil
            
            for i = start_line, #lines do
              local line = lines[i]
              
              if not in_function then
                -- Find function start
                if line:match("^%s*def " .. task_name) then
                  in_function = true
                  indent_level = line:match("^(%s*)")
                  table.insert(source_lines, line)
                end
              else
                -- Check if we've reached the end of the function
                local current_indent = line:match("^(%s*)")
                if current_indent and #current_indent <= #(indent_level or "") and line:match("%S") then
                  break
                end
                table.insert(source_lines, line)
              end
            end
            
            task.source_code = table.concat(source_lines, "\n")
          end
        end
      end
      
      return task
    end
  end
  
  return nil
end

--- Get task dependencies and relationships
-- @return table Task dependency information
function M.get_task_dependencies()
  local python_script = [[
import sys
import importlib.util
import ast
from pathlib import Path

def analyze_task_dependencies(tasks_file_path):
    """Analyze task dependencies by parsing the AST."""
    try:
        with open(tasks_file_path, 'r') as f:
            tree = ast.parse(f.read())
        
        dependencies = {}
        
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                task_name = node.name
                deps = []
                
                # Look for c.run() calls which indicate task dependencies
                for child in ast.walk(node):
                    if isinstance(child, ast.Call):
                        if (isinstance(child.func, ast.Attribute) and 
                            isinstance(child.func.value, ast.Name) and
                            child.func.value.id == 'c' and
                            child.func.attr == 'run'):
                            # This is a c.run() call
                            if child.args and isinstance(child.args[0], ast.Constant):
                                deps.append(child.args[0].value)
                
                if deps:
                    dependencies[task_name] = deps
        
        return dependencies
        
    except Exception as e:
        print(f"Error analyzing dependencies: {e}", file=sys.stderr)
        return {}

if __name__ == "__main__":
    tasks_file = sys.argv[1] if len(sys.argv) > 1 else "tasks.py"
    deps = analyze_task_dependencies(tasks_file)
    
    for task, task_deps in deps.items():
        print(f"TASK:{task}")
        for dep in task_deps:
            print(f"DEP:{dep}")
        print("---")
]]
  
  local tasks_file = vim.fn.getcwd() .. "/tasks.py"
  if vim.fn.filereadable(tasks_file) ~= 1 then
    return {}
  end
  
  -- Execute dependency analysis
  local temp_script = vim.fn.tempname() .. "_deps.py"
  local file = io.open(temp_script, "w")
  if not file then
    return {}
  end
  
  file:write(python_script)
  file:close()
  
  local handle = io.popen(string.format("python3 %s %s 2>/dev/null", temp_script, tasks_file))
  if not handle then
    os.remove(temp_script)
    return {}
  end
  
  local result = handle:read("*a")
  handle:close()
  os.remove(temp_script)
  
  -- Parse dependencies
  local dependencies = {}
  local current_task = nil
  
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^TASK:") then
      current_task = line:sub(6)
      dependencies[current_task] = {}
    elseif line:match("^DEP:") and current_task then
      table.insert(dependencies[current_task], line:sub(5))
    end
  end
  
  return dependencies
end

return M 