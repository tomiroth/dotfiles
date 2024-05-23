local lsp = require('lsp-zero')

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = { 'tsserver', 'rust_analyzer', 'intelephense', 'lua_ls' },
  automatic_installation = true,     -- Automatically install language servers
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({})
    end,
    ['rust_analyzer'] = lsp.noop,
  }
})


vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = {"*.rs"},
  callback = function()
    if vim.bo.filetype == "rust" then
      vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
    end
  end,
})


-- Configure lsp-zero
lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr}
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, opts)

  vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "<leader>df", "<cmd>Telescope diagnostics<cr>", opts)

  vim.keymap.set('n', '<leader>vca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)

  vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
end)
