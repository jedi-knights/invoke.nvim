-- lua/invoke_nvim/args.lua
-- Handles task arguments and interactive input

local M = {}

-- Get task help to extract argument information
function M.get_task_help(task_name)
  local handle = io.popen(string.format("invoke %s --help", task_name))
  if not handle then return {} end
  
  local result = handle:read("*a")
  handle:close()
  
  local args = {}
  local lines = vim.split(result, "\n")
  
  for _, line in ipairs(lines) do
    -- Look for argument patterns like --arg, -a, etc.
    local arg = line:match("^%s*[-]+([%w-]+)")
    if arg and arg ~= "help" and arg ~= "version" then
      local desc = line:match("^%s*[-]+[%w-]+%s+(.+)$")
      table.insert(args, {
        name = arg,
        description = desc or "",
        required = line:match("required") ~= nil
      })
    end
  end
  
  return args
end

-- Prompt for task arguments
function M.prompt_for_args(task_name, presets)
  local args = M.get_task_help(task_name)
  if #args == 0 then
    return {}
  end
  
  local result = {}
  local options = require("invoke_nvim").options
  
  -- Check for presets
  if presets and presets[task_name] then
    local preset_choice = vim.fn.inputlist({
      "Choose argument preset for '" .. task_name .. "':",
      "1. No arguments",
      "2. Use preset: " .. vim.inspect(presets[task_name]),
      "3. Enter manually"
    })
    
    if preset_choice == 2 then
      return presets[task_name]
    elseif preset_choice == 1 then
      return {}
    end
  end
  
  -- Manual argument input
  for _, arg in ipairs(args) do
    local prompt = string.format("Enter value for --%s%s: ", 
      arg.name, 
      arg.required and " (required)" or ""
    )
    
    local value = vim.fn.input(prompt)
    if value and value ~= "" then
      result[arg.name] = value
    elseif arg.required then
      vim.notify("Required argument --" .. arg.name .. " not provided", vim.log.levels.ERROR)
      return nil
    end
  end
  
  return result
end

-- Build command string with arguments
function M.build_command(task_name, args)
  local cmd = "invoke " .. task_name
  
  if args and type(args) == "table" then
    for arg_name, arg_value in pairs(args) do
      if type(arg_value) == "boolean" and arg_value then
        cmd = cmd .. " --" .. arg_name
      elseif type(arg_value) == "string" and arg_value ~= "" then
        cmd = cmd .. " --" .. arg_name .. " " .. vim.fn.shellescape(arg_value)
      elseif type(arg_value) == "number" then
        cmd = cmd .. " --" .. arg_name .. " " .. tostring(arg_value)
      end
    end
  end
  
  return cmd
end

-- Get argument history for a task
function M.get_arg_history(task_name)
  local history = require("invoke_nvim.history").get_history()
  local task_history = {}
  
  for _, entry in ipairs(history) do
    if entry.task == task_name and entry.args and next(entry.args) then
      table.insert(task_history, entry.args)
    end
  end
  
  return task_history
end

-- Suggest arguments based on history
function M.suggest_args_from_history(task_name)
  local arg_history = M.get_arg_history(task_name)
  if #arg_history == 0 then
    return nil
  end
  
  -- Return the most recent argument set
  return arg_history[1]
end

return M 