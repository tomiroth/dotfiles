local gh = function(x) return 'https://github.com/' .. x end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})

-- Loaded at startup.
vim.pack.add({
  --Dependancies
  { src = gh('nvim-lua/plenary.nvim') },
  { src = gh('sindrets/diffview.nvim') },
  { src = gh('MunifTanjim/nui.nvim') },

  --Packages
  { src = gh('benfowler/telescope-luasnip.nvim') },
  { src = gh('christoomey/vim-tmux-navigator') }, -- plenary
  { src = gh('folke/which-key.nvim') },
  { src = gh('neogitorg/neogit') }, --planary, telescope
  { src = gh('folke/noice.nvim') }, --nui
  { src = gh('neovim/nvim-lspconfig') },
  { src = gh('hrsh7th/cmp-nvim-lsp') },
  { src = gh('mason-org/mason.nvim') },
  { src = gh('mason-org/mason-lspconfig.nvim') },
  { src = gh('nvim-treesitter/nvim-treesitter') },
  { src = gh('folke/flash.nvim') },
  { src = gh('github/copilot.vim') },
  { src = gh('stevearc/conform.nvim') },
  { src = gh('catppuccin/nvim'), name = 'catppuccin' },
  { src = gh('will133/vim-dirdiff') },
})

-- Registered/installed at startup, but added to 'runtimepath' on first use.
-- Keymaps/autocmds that use them live in after/plugin/* and call
-- require('tom.lazy').load_plugin() before requiring the plugin module.
vim.pack.add({
  { src = gh('nvim-telescope/telescope.nvim') },                                                        -- plenary
  { src = gh('ThePrimeagen/harpoon'),           version = '87b1a3506211538f460786c23f98ec63ad9af4e5' }, -- plenary
  { src = gh('hrsh7th/nvim-cmp') },
}, { load = function() end })
