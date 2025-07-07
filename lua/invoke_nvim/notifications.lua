-- lua/invoke_nvim/notifications.lua
-- Handles task execution monitoring and notifications

local M = {}

local active_tasks = {}

-- Start monitoring a task
function M.start_monitoring(task_name, terminal_id)
  active_tasks[terminal_id] = {
    task_name = task_name,
    start_time = os.time(),
    status = "running"
  }
  
  if require("invoke_nvim").options.enable_notifications then
    vim.notify("Started task: " .. task_name, vim.log.levels.INFO, {
      title = "Invoke.nvim",
      timeout = 3000
    })
  end
end

-- Stop monitoring a task
function M.stop_monitoring(terminal_id, exit_code)
  local task_info = active_tasks[terminal_id]
  if not task_info then return end
  
  local end_time = os.time()
  local runtime = end_time - task_info.start_time
  local status = exit_code == 0 and "completed" or "failed"
  
  -- Update history with runtime
  local history = require("invoke_nvim.history")
  local entry = history.get_history()[1]
  if entry and entry.task == task_info.task_name then
    entry.runtime = runtime
    history.add_to_history(task_info.task_name, entry.args)
  end
  
  -- Show notification
  if require("invoke_nvim").options.enable_notifications then
    local message = string.format("Task '%s' %s (%ds)", 
      task_info.task_name, 
      status, 
      runtime
    )
    
    local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
    vim.notify(message, level, {
      title = "Invoke.nvim",
      timeout = 5000
    })
  end
  
  active_tasks[terminal_id] = nil
end

-- Get active tasks
function M.get_active_tasks()
  return active_tasks
end

-- Check if a task is running
function M.is_task_running(task_name)
  for _, task_info in pairs(active_tasks) do
    if task_info.task_name == task_name then
      return true
    end
  end
  return false
end

-- Show task progress
function M.show_progress(task_name)
  for terminal_id, task_info in pairs(active_tasks) do
    if task_info.task_name == task_name then
      local elapsed = os.time() - task_info.start_time
      local message = string.format("Task '%s' running for %ds", task_name, elapsed)
      vim.notify(message, vim.log.levels.INFO, {
        title = "Invoke.nvim Progress",
        timeout = 2000
      })
      return
    end
  end
end

-- Show task statistics
function M.show_stats()
  local tasks = require("invoke_nvim.list").get_tasks()
  local stats = require("invoke_nvim.analyzer").get_task_stats(tasks)
  local history = require("invoke_nvim.history").get_history()
  local favorites = require("invoke_nvim.history").get_favorites()
  
  local message = string.format(
    "Tasks: %d total, %d favorites\nHistory: %d entries\nActive: %d running",
    stats.total,
    stats.favorites,
    #history,
    #active_tasks
  )
  
  vim.notify(message, vim.log.levels.INFO, {
    title = "Invoke.nvim Stats",
    timeout = 5000
  })
end

-- Show task completion summary
function M.show_completion_summary(task_name, runtime, success)
  local message = string.format(
    "Task '%s' %s in %ds",
    task_name,
    success and "completed successfully" or "failed",
    runtime
  )
  
  local level = success and vim.log.levels.INFO or vim.log.levels.ERROR
  vim.notify(message, level, {
    title = "Invoke.nvim",
    timeout = 4000
  })
end

return M 