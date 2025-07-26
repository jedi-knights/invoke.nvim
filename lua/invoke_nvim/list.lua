-- lua/invoke_nvim/list.lua
-- Parse the output of `invoke --list` to extract available tasks
-- Enhanced with introspection capabilities

local M = {}

--- Get a list of available Invoke tasks using introspection
-- @param use_introspection boolean Whether to use Python introspection (default: from config)
-- @return table List of task tables with detailed information
function M.get_tasks(use_introspection)
  local init = require("invoke_nvim")
  use_introspection = use_introspection ~= nil and use_introspection or init.options.enable_introspection
  
  local detector = require("invoke_nvim.detector")
  
  -- Check if we should allow operations
  if not detector.should_allow_operations() then
    return {}
  end
  
  -- Try introspection first if enabled
  if use_introspection then
    local introspector = require("invoke_nvim.introspector")
    local introspected_tasks = introspector.get_tasks_via_introspection()
    
    if #introspected_tasks > 0 then
      -- Convert introspection format to standard format
      local tasks = {}
      for _, task in ipairs(introspected_tasks) do
        table.insert(tasks, {
          name = task.name,
          desc = task.doc or "",
          signature = task.signature,
          source_file = task.source_file,
          line_number = task.line_number,
          aliases = {}, -- Introspection doesn't provide aliases
        })
      end
      return tasks
    end
  end
  
  -- Fallback to traditional invoke --list method if enabled
  if init.options.fallback_to_invoke_list then
    return M.get_tasks_via_invoke()
  end
  
  return {}
end

--- Get tasks using traditional invoke --list method
-- @return table List of task tables with `name`, `desc`, and optional `aliases`
function M.get_tasks_via_invoke()
  -- Run `invoke --list` and capture output
  local handle = io.popen("invoke --list --no-color 2>/dev/null")
  if not handle then return {} end

  local result = handle:read("*a")
  handle:close()

  local tasks = {}

  -- Parse each line for task name, aliases, and description
  for line in result:gmatch("[^\r\n]+") do
    -- Skip header lines
    if line:match("^Available") then
      goto continue
    end
    
    -- Format with aliases: task_name [alias1, alias2]  Description
    local name, aliases, desc = line:match("^(%S+)%s+%[([%w_,%s]+)%]%s+(.+)$")

    -- Fallback: task_name  Description (no aliases)
    if not name then
      name, desc = line:match("^(%S+)%s+(.+)$")
    end

    -- Insert parsed task into results
    if name and name ~= "" then
      table.insert(tasks, {
        name = name,
        desc = desc or "",
        aliases = aliases and vim.split(aliases:gsub("%s", ""), ",") or {},
      })
    end
    
    ::continue::
  end

  return tasks
end

--- Get detailed information about a specific task
-- @param task_name string Name of the task
-- @return table Detailed task information or nil if not found
function M.get_task_details(task_name)
  local introspector = require("invoke_nvim.introspector")
  return introspector.get_task_details(task_name)
end

--- Get task dependencies and relationships
-- @return table Task dependency information
function M.get_task_dependencies()
  local introspector = require("invoke_nvim.introspector")
  return introspector.get_task_dependencies()
end

return M
