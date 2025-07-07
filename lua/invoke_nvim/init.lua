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

  -- Register keymaps
  vim.keymap.set("n", M.options.keymap, function()
    require("invoke_nvim.snacks").open()
  end, { desc = "Invoke: Open Task Picker" })

  -- Setup integrations
  require("invoke_nvim.integrations").setup_all()
end

return M
