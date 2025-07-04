local lsp = require('lsp-zero')

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = { 'rust_analyzer', 'intelephense', 'lua_ls' },
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
  vim.keymap.set('n', '<leader>vs', vim.lsp.buf.workspace_symbol, {buffer = bufnr, desc = "Query symbols"})
  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, {buffer = bufnr, desc = "Diagnostic"})
  vim.keymap.set('n', '<leader>vD',function()
    require("telescope.builtin").diagnostics({
      bufnr = 0,            -- current buffer only
      sort_by = "severity", -- put errors on top (optional)
    })
  end, {buffer = bufnr, desc = "Telescope Dagnostic"})

  vim.keymap.set('n', '<leader>va', vim.lsp.buf.code_action, {buffer = bufnr, desc = "Code actions"})
  vim.keymap.set('n', '<leader>vr', vim.lsp.buf.references, {buffer = bufnr, desc = "References"})
  vim.keymap.set('n', '<leader>vn', vim.lsp.buf.rename, {buffer = bufnr, desc = "References"})

  vim.keymap.set('i', '<C-H>', vim.lsp.buf.signature_help, opts)
end)
