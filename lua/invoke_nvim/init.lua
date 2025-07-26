-- lua/invoke_nvim/init.lua
-- Plugin setup and user-facing configuration

local M = {}

-- Setup function for configuring the plugin
function M.setup(opts)
  opts = opts or {}

  -- Merge user options with defaults
  M.options = vim.tbl_deep_extend("force", {
    keymap = "<leader>ti", -- Default keymap to open the task picker
    -- Task execution settings
    term_direction = "float", -- "float", "horizontal", "vertical"
    close_on_exit = false, -- Keep terminal open after task completes
    show_preview = true, -- Show task preview in picker
    
    -- Task history and favorites
    enable_history = true, -- Track recently run tasks
    max_history = 10, -- Maximum number of recent tasks to remember
    enable_favorites = true, -- Allow marking tasks as favorites
    
    -- Task arguments
    enable_args = true, -- Enable interactive argument input
    arg_presets = {}, -- Predefined argument presets for tasks
    
    -- Notifications
    enable_notifications = true, -- Show task completion notifications
    
    -- Integration settings
    overseer_integration = false, -- Integrate with overseer.nvim
    trouble_integration = false, -- Integrate with trouble.nvim
    which_key_integration = false, -- Integrate with which-key.nvim
    
    -- Introspection settings
    enable_introspection = true, -- Use Python introspection for task discovery
    fallback_to_invoke_list = true, -- Fallback to invoke --list if introspection fails
    show_source_info = true, -- Show source file and line number in task details
    analyze_dependencies = true, -- Analyze task dependencies via AST parsing
  }, opts)

  -- Create user commands
  vim.api.nvim_create_user_command("InvokeTasks", function()
    require("invoke_nvim.snacks").open()
  end, { desc = "Open Invoke Task Picker" })

  vim.api.nvim_create_user_command("InvokeHistory", function()
    require("invoke_nvim.snacks").open_history()
  end, { desc = "Open Invoke Task History" })

  vim.api.nvim_create_user_command("InvokeFavorites", function()
    require("invoke_nvim.snacks").open_favorites()
  end, { desc = "Open Invoke Favorite Tasks" })

  vim.api.nvim_create_user_command("InvokeByCategory", function()
    require("invoke_nvim.snacks").open_by_category()
  end, { desc = "Open Invoke Tasks by Category" })

  vim.api.nvim_create_user_command("InvokeStats", function()
    require("invoke_nvim.notifications").show_stats()
  end, { desc = "Show Invoke Task Statistics" })

  vim.api.nvim_create_user_command("InvokeClearHistory", function()
    require("invoke_nvim.history").clear_history()
    vim.notify("Task history cleared", vim.log.levels.INFO)
  end, { desc = "Clear Invoke Task History" })

  vim.api.nvim_create_user_command("InvokeClearFavorites", function()
    require("invoke_nvim.history").clear_favorites()
    vim.notify("Favorite tasks cleared", vim.log.levels.INFO)
  end, { desc = "Clear Invoke Favorite Tasks" })

  vim.api.nvim_create_user_command("InvokeStatus", function()
    local detector = require("invoke_nvim.detector")
    local status = detector.get_environment_status()
    
    local message = "Invoke.nvim Environment Status:\n\n"
    message = message .. "Invoke available: " .. (status.invoke_available and "✓" or "✗") .. "\n"
    message = message .. "Tasks.py present: " .. (status.tasks_file_present and "✓" or "✗") .. "\n"
    message = message .. "Python project: " .. (status.python_project and "✓" or "✗") .. "\n"
    message = message .. "Global tasks: " .. (status.has_global_tasks and "✓" or "✗") .. "\n"
    
    if status.invoke_version then
      message = message .. "Invoke version: " .. status.invoke_version .. "\n"
    end
    
    vim.notify(message, vim.log.levels.INFO, { title = "Invoke.nvim Status" })
  end, { desc = "Show Invoke Environment Status" })

  vim.api.nvim_create_user_command("InvokeSetup", function()
    local detector = require("invoke_nvim.detector")
    detector.show_setup_help()
  end, { desc = "Show Invoke Setup Help" })

  vim.api.nvim_create_user_command("InvokeIntrospect", function()
    local list = require("invoke_nvim.list")
    local tasks = list.get_tasks(true) -- Force introspection
    
    if #tasks == 0 then
      vim.notify("No tasks found via introspection", vim.log.levels.WARN)
      return
    end
    
    local message = "Tasks discovered via introspection:\n\n"
    for _, task in ipairs(tasks) do
      message = message .. string.format("• %s", task.name)
      if task.desc and task.desc ~= "" then
        message = message .. string.format(" - %s", task.desc)
      end
      if task.signature then
        message = message .. string.format(" (%s)", task.signature)
      end
      message = message .. "\n"
    end
    
    vim.notify(message, vim.log.levels.INFO, { title = "Invoke Introspection Results" })
  end, { desc = "Show Tasks Discovered via Introspection" })

  vim.api.nvim_create_user_command("InvokeTaskDetails", function(opts)
    if not opts.args or opts.args == "" then
      vim.notify("Please provide a task name: InvokeTaskDetails <task_name>", vim.log.levels.ERROR)
      return
    end
    
    local list = require("invoke_nvim.list")
    local task_details = list.get_task_details(opts.args)
    
    if not task_details then
      vim.notify(string.format("Task '%s' not found", opts.args), vim.log.levels.ERROR)
      return
    end
    
    local message = string.format("Task Details for '%s':\n\n", task_details.name)
    message = message .. string.format("Description: %s\n", task_details.doc or "No description")
    message = message .. string.format("Signature: %s\n", task_details.signature or "Unknown")
    message = message .. string.format("Source: %s:%s\n", task_details.source_file or "Unknown", task_details.line_number or "Unknown")
    
    if task_details.source_code then
      message = message .. "\nSource Code:\n" .. task_details.source_code
    end
    
    vim.notify(message, vim.log.levels.INFO, { title = "Task Details" })
  end, { desc = "Show Detailed Information for a Task", nargs = 1 })

  vim.api.nvim_create_user_command("InvokeDependencies", function()
    local list = require("invoke_nvim.list")
    local dependencies = list.get_task_dependencies()
    
    if not dependencies or vim.tbl_isempty(dependencies) then
      vim.notify("No task dependencies found", vim.log.levels.INFO)
      return
    end
    
    local message = "Task Dependencies:\n\n"
    for task_name, deps in pairs(dependencies) do
      message = message .. string.format("• %s:\n", task_name)
      for _, dep in ipairs(deps) do
        message = message .. string.format("  - %s\n", dep)
      end
      message = message .. "\n"
    end
    
    vim.notify(message, vim.log.levels.INFO, { title = "Task Dependencies" })
  end, { desc = "Show Task Dependencies" })

  -- Register keymaps
  vim.keymap.set("n", M.options.keymap, function()
    require("invoke_nvim.snacks").open()
  end, { desc = "Invoke: Open Task Picker" })

  -- Setup integrations
  require("invoke_nvim.integrations").setup_all()
end

return M
