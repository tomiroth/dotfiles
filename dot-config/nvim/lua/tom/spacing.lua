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

-- Prettier configuration
vim.g['prettier#autoformat'] = 1
vim.g['prettier#autoformat_config_present'] = 1


-- state variable
local prettier_enabled = true

-- augroup for Prettier
local fmt_group = vim.api.nvim_create_augroup("fmt", { clear = true })

-- autocmd definition
vim.api.nvim_create_autocmd("BufWritePre", {
  group = fmt_group,
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.css", "*.scss", "*.html", "*.yaml", "*.yml" },
  callback = function()
    if prettier_enabled then
      vim.cmd("silent! Prettier")
    end
  end,
})

-- toggle function
function TogglePrettier()
  prettier_enabled = not prettier_enabled
  if prettier_enabled then
    print("✅ Prettier formatting enabled")
  else
    print("⛔ Prettier formatting disabled")
  end
end

-- create a user command :TogglePrettier
vim.api.nvim_create_user_command("TogglePrettier", TogglePrettier, {})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.rs",
    callback = function()
        vim.lsp.buf.format({ async = true })
    end,
})

