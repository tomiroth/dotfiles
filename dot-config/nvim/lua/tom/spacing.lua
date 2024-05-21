-- Default to 4-space tab for all files
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true

-- Function to set 2-space tab for TypeScript files
local function set_ts_indent()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.expandtab = true
end

-- Autocommand to trigger the function for TypeScript files
vim.api.nvim_create_autocmd("FileType", {
    pattern = {"typescript", "typescriptreact", "javascript", "javascriptreact"},
    callback = set_ts_indent
})
