local M = {}

function M.load()
  require('tom.lazy').load_plugin('nvim-cmp')
  if vim.g.tom_cmp_loaded then
    return
  end
  vim.g.tom_cmp_loaded = true

  local cmp = require('cmp')
  cmp.setup({
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
    }, {
      { name = 'buffer' },
    }),
    mapping = cmp.mapping.preset.insert({
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
  })

  -- cmp-nvim-lsp's InsertEnter handler was suppressed at startup because it
  -- requires cmp; re-register it now that cmp is available.
  require('cmp_nvim_lsp').setup()
end

return M
