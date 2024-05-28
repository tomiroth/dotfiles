-- Load packer.nvim
vim.cmd [[packadd packer.nvim]]

-- Use packer to manage plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'  -- Package manager

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
  -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use( 'nvim-treesitter/nvim-treesitter', {run= ':TSUpdate'})

  use('nvim-treesitter/playground')


  use {
	  'VonHeikemen/lsp-zero.nvim',
	  branch = 'v3.x',
	  requires = {
	    {'williamboman/mason.nvim'},
	    {'williamboman/mason-lspconfig.nvim'},

	    {'neovim/nvim-lspconfig'},
	    {'hrsh7th/nvim-cmp'},
	    {'hrsh7th/cmp-nvim-lsp'},
	    {'L3MON4D3/LuaSnip'},
	  }
	}
	use {
	  'NeogitOrg/neogit',
	  requires = {
	    { 'nvim-lua/plenary.nvim' },         -- required
	    { 'sindrets/diffview.nvim', opt = true },        -- optional - Diff integration

	    -- Only one of these is needed, not both.
	    { 'nvim-telescope/telescope.nvim', opt = true }, -- optional
	    { 'ibhagwan/fzf-lua', opt = true },              -- optional
	  },
	  config = true
	}


	use {
	  'phaazon/hop.nvim',
	  branch = 'v2', -- optional but strongly recommended
	}

	use 'christoomey/vim-tmux-navigator'
	use { "catppuccin/nvim", as = "catppuccin" }

    use {
      'prettier/vim-prettier',
      run = 'yarn install --frozen-lockfile --production' -- Ensures dependencies are installed correctly
    }
    use {
      'mrcjkb/rustaceanvim',
    }
    use "nvim-lua/plenary.nvim"
    use {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        requires = { {"nvim-lua/plenary.nvim"} }
    }

end)
