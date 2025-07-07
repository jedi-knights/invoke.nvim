-- plugin/invoke.lua
-- Entryp point for invoke.nvim

if vim.g.loaded_invoke_nvim then
    return
end

vim.g.loaded_invoke_nvim = true

require("invoke_nvim").setup()

