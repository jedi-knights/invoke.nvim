-- lua/invoke_nvim/integrations.lua
-- Handles integrations with other Neovim plugins

local M = {}

-- Overseer.nvim integration
function M.setup_overseer()
  if not require("invoke_nvim").options.overseer_integration then
    return
  end
  
  local overseer = require("overseer")
  if not overseer then
    vim.notify("overseer.nvim not found", vim.log.levels.WARN)
    return
  end
  
  -- Register invoke task template
  overseer.register_template({
    name = "Invoke Task",
    builder = function(params)
      return {
        cmd = { "invoke" },
        args = { params.task_name },
        name = "invoke " .. params.task_name,
        components = {
          { "on_output_quickfix", open = true },
          "default",
        },
      }
    end,
    params = {
      task_name = {
        type = "string",
        required = true,
      },
    },
  })
end

-- Trouble.nvim integration
function M.setup_trouble()
  if not require("invoke_nvim").options.trouble_integration then
    return
  end
  
  local trouble = require("trouble")
  if not trouble then
    vim.notify("trouble.nvim not found", vim.log.levels.WARN)
    return
  end
  
  -- Add trouble support for task errors
  -- This would require parsing task output for errors
end

-- Which-key.nvim integration
function M.setup_which_key()
  if not require("invoke_nvim").options.which_key_integration then
    return
  end
  
  local which_key = require("which-key")
  if not which_key then
    vim.notify("which-key.nvim not found", vim.log.levels.WARN)
    return
  end
  
  -- Register invoke keymaps
  which_key.register({
    ["<leader>ti"] = { "<cmd>InvokeTasks<cr>", "Invoke: Open Task Picker" },
    ["<leader>th"] = { "<cmd>InvokeHistory<cr>", "Invoke: Show History" },
    ["<leader>tf"] = { "<cmd>InvokeFavorites<cr>", "Invoke: Show Favorites" },
    ["<leader>ts"] = { "<cmd>InvokeStats<cr>", "Invoke: Show Stats" },
  })
end

-- Setup all integrations
function M.setup_all()
  M.setup_overseer()
  M.setup_trouble()
  M.setup_which_key()
end

-- Create overseer task from invoke task
function M.create_overseer_task(task_name, args)
  if not require("invoke_nvim").options.overseer_integration then
    return nil
  end
  
  local overseer = require("overseer")
  if not overseer then
    return nil
  end
  
  local cmd = require("invoke_nvim.args").build_command(task_name, args)
  local task = overseer.new_task({
    cmd = vim.split(cmd, " "),
    name = "invoke " .. task_name,
    components = {
      { "on_output_quickfix", open = true },
      "default",
    },
  })
  
  return task
end

return M 