local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add({
  --Dependancies
  { src = gh('nvim-lua/plenary.nvim') },
  { src = gh('sindrets/diffview.nvim') },
  { src = gh('MunifTanjim/nui.nvim') },

  --Packages
  { src = gh('0Risotto/rainbow12') },
  { src = gh('nvim-telescope/telescope.nvim') }, -- plenary
  { src = gh('christoomey/vim-tmux-navigator') }, -- plenary
  { src = gh('ThePrimeagen/harpoon'), version = '87b1a3506211538f460786c23f98ec63ad9af4e5' }, -- plenary
  { src = gh('folke/which-key.nvim') },
  { src = gh('neogitorg/neogit') }, --planary, telescope
  { src = gh('folke/noice.nvim') }, --nui

  --
  -- -- Specify plugin's name (here the plugin will be called "plugin1"
  -- -- instead of "generic-name")
  -- { src = 'https://github.com/user/generic-name', name = 'plugin2' },
  --
  -- -- Specify version to follow during install and update
  -- {
  --   src = 'https://github.com/user/plugin3',
  --   -- Version constraint, see |vim.version.range()|
  --   version = vim.version.range('1.0'),
  -- }
  -- {
  --   src = 'https://github.com/user/plugin4',
  --   -- Git branch, tag, or commit hash
  --   version = 'main',
  -- },
})
