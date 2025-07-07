-- lua/invoke_nvim/runner.lua
-- Responsible for running selected Invoke tasks using toggleterm

local M = {}

--- Run the given Invoke task name with optional arguments
-- @param task_name string: The name of the invoke task to run
-- @param args table: Optional arguments for the task
function M.run(task_name, args)
  local options = require("invoke_nvim").options
  local history = require("invoke_nvim.history")
  local notifications = require("invoke_nvim.notifications")
  local args_manager = require("invoke_nvim.args")
  
  -- Check if task is already running
  if notifications.is_task_running(task_name) then
    vim.notify("Task '" .. task_name .. "' is already running", vim.log.levels.WARN)
    return
  end
  
  -- Get arguments if not provided
  if not args and options.enable_args then
    args = args_manager.prompt_for_args(task_name, options.arg_presets)
    if args == nil then -- User cancelled
      return
    end
  end
  
  -- Build command
  local cmd = args_manager.build_command(task_name, args)
  
  -- Add to history
  if options.enable_history then
    history.add_to_history(task_name, args)
  end
  
  -- Check for overseer integration
  if options.overseer_integration then
    local overseer_task = require("invoke_nvim.integrations").create_overseer_task(task_name, args)
    if overseer_task then
      overseer_task:start()
      return
    end
  end
  
  -- Use toggleterm as fallback
  local Terminal = require("toggleterm.terminal").Terminal
  
  -- Create terminal with configured settings
  local term = Terminal:new({
    cmd = cmd,
    direction = options.term_direction,
    close_on_exit = options.close_on_exit,
    hidden = true,
    on_exit = function(term_obj, job_id, exit_code)
      notifications.stop_monitoring(term_obj.id, exit_code)
    end,
  })
  
  -- Start monitoring
  notifications.start_monitoring(task_name, term.id)
  
  -- Open terminal
  term:toggle()
end

--- Run task with overseer if available
function M.run_with_overseer(task_name, args)
  local options = require("invoke_nvim").options
  if not options.overseer_integration then
    return M.run(task_name, args)
  end
  
  local overseer_task = require("invoke_nvim.integrations").create_overseer_task(task_name, args)
  if overseer_task then
    overseer_task:start()
    return true
  end
  
  return false
end

--- Run task in background
function M.run_background(task_name, args)
  local args_manager = require("invoke_nvim.args")
  local cmd = args_manager.build_command(task_name, args)
  
  -- Run in background
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      local notifications = require("invoke_nvim.notifications")
      notifications.show_completion_summary(task_name, 0, exit_code == 0)
    end
  })
  
  vim.notify("Started background task: " .. task_name, vim.log.levels.INFO)
end

return M
