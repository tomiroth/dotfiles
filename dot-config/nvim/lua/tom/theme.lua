vim.cmd.colorscheme "catppuccin"
-- Ensure this runs after your colorscheme is loaded
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
