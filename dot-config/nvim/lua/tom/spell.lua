-- Spell-check markdown automatically
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  command = "setlocal spell spelllang=en_us",
})
