-- plugin/invoke.lua
-- Entry point for invoke.nvim

if vim.g.loaded_invoke_nvim then
    return
end

-- Check and load on startup
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    callback = function()
        local detector = require("invoke_nvim.detector")
        if detector.should_load() then
            vim.g.loaded_invoke_nvim = true
            require("invoke_nvim").setup()
        end
    end,
})

-- Check and load when directory changes (for project switching)
vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = function()
        if vim.g.loaded_invoke_nvim then
            return -- Already loaded
        end
        local detector = require("invoke_nvim.detector")
        if detector.should_load() then
            vim.g.loaded_invoke_nvim = true
            require("invoke_nvim").setup()
        end
    end,
})

