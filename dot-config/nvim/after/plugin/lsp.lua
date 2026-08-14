require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = { "lua_ls", "phpactor", "ts_ls", "pyright", "rust_analyzer", "zls" },
    automatic_enable = false,
}
vim.lsp.enable({ "lua_ls", "phpactor", "ts_ls", "pyright", "rust_analyzer", "zls" })
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})
vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using (most
        -- likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Tell the language server how to find Lua modules same way as Neovim
        -- (see `:h lua-module-load`)
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- For LSP Settings Type Annotations: https://github.com/neovim/nvim-lspconfig#lsp-settings-type-annotations
          vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
          -- Depending on the usage, you might want to add additional paths
          -- here.
          -- '${3rd}/luv/library',
          -- '${3rd}/busted/library',
        },
        -- Or pull in all of 'runtimepath'.
        -- NOTE: this is a lot slower and will cause issues when working on
        -- your own configuration.
        -- See https://github.com/neovim/nvim-lspconfig/issues/3189
        -- library = vim.api.nvim_get_runtime_file('', true),
      },
    })
  end,
  settings = {
    Lua = {},
  },
})

require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_format = "fallback",
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>vs', vim.lsp.buf.workspace_symbol, { buffer = args.buf, desc = "Query symbols" })
    vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, { buffer = args.buf, desc = "Diagnostic" })
    vim.keymap.set('n', '<leader>vD', function()
      require("telescope.builtin").diagnostics({ bufnr = 0, sort_by = "severity" })
    end, { buffer = args.buf, desc = "Telescope Diagnostic" })
    vim.keymap.set('n', '<leader>va', vim.lsp.buf.code_action, { buffer = args.buf, desc = "Code actions" })
    vim.keymap.set('n', '<leader>vr', vim.lsp.buf.references, { buffer = args.buf, desc = "References" })
    vim.keymap.set('n', '<leader>vn', vim.lsp.buf.rename, { buffer = args.buf, desc = "Rename" })
    vim.keymap.set('i', '<C-H>', vim.lsp.buf.signature_help, opts)
  end,
})
