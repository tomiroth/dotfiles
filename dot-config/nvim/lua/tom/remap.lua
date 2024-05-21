vim.g.mapleader = " "
vim.keymap.set("n", "<leader>d", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit)


vim.keymap.set("n", "<leader>bj", vim.cmd.bn)
vim.keymap.set("n", "<leader>bk", vim.cmd.bp)
vim.keymap.set("n", "<leader>bx", vim.cmd.bd)


-- Todo: Work out how to use the hyper key for binding.
vim.keymap.set("n", "<Esc>[91;10u", vim.cmd.Neogit)


-- vim.api.nvim_set_keymap('n', '<Esc>[91;10u', ':echo "Hyper+X pressed"<CR>', { noremap = true, silent = true })
