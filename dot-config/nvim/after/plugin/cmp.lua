-- cmp-nvim-lsp registers an InsertEnter autocmd that requires cmp. Suppress
-- it until cmp is loaded on the first insert.
vim.api.nvim_create_augroup('cmp_nvim_lsp', { clear = true })

vim.api.nvim_create_autocmd('InsertEnter', {
  once = true,
  callback = function()
    require('tom.cmp').load()
  end,
})
