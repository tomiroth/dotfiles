vim.opt.termguicolors = true

require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = true,
})

vim.cmd.colorscheme("catppuccin")
