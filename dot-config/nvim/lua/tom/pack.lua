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

vim.pack.add({
  --Dependancies
  { src = gh('nvim-lua/plenary.nvim') },
  { src = gh('sindrets/diffview.nvim') },
  { src = gh('MunifTanjim/nui.nvim') },

  --Packages
  { src = gh('nvim-telescope/telescope.nvim') }, -- plenary
  { src = gh('christoomey/vim-tmux-navigator') }, -- plenary
  { src = gh('ThePrimeagen/harpoon'), version = '87b1a3506211538f460786c23f98ec63ad9af4e5' }, -- plenary
  { src = gh('folke/which-key.nvim') },
  { src = gh('neogitorg/neogit') }, --planary, telescope
  { src = gh('folke/noice.nvim') }, --nui
  { src = gh('neovim/nvim-lspconfig') },
  { src = gh('hrsh7th/nvim-cmp') },
  { src = gh('hrsh7th/cmp-nvim-lsp') },
  { src = gh('mason-org/mason.nvim') },
  { src = gh('mason-org/mason-lspconfig.nvim') },
  { src = gh('nvim-treesitter/nvim-treesitter') },
  { src = gh('hadronized/hop.nvim') },
  { src = gh('github/copilot.vim') },
})
