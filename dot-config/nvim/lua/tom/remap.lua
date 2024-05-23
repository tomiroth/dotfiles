vim.g.mapleader = " "
vim.keymap.set("n", "<leader>d", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit)
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>")


vim.keymap.set("n", "<leader>bj", vim.cmd.bn)
vim.keymap.set("n", "<leader>bk", vim.cmd.bp)
vim.keymap.set("n", "<leader>bx", vim.cmd.bd)

-- Map <Leader>y to yank the current line to the system clipboard
vim.api.nvim_set_keymap('n', '<Leader>y', '"+yy', { noremap = true, silent = true })
-- Map <leader>y to yank current selecttion to system clipboard
vim.api.nvim_set_keymap('v', '<Leader>y', '"+y', { noremap = true, silent = true })
-- Map <Leader>y to paste the current line to the system clipboard
vim.api.nvim_set_keymap('n', '<Leader>Y', '"+p', { noremap = true, silent = true })
-- Map <leader>y to paste current selecttion to system clipboard
vim.api.nvim_set_keymap('v', '<Leader>Y', '"+p', { noremap = true, silent = true })

-- Todo: Work out how to use the hyper key for binding.
vim.keymap.set("n", "<Esc>[91;10u", vim.cmd.Neogit)


-- vim.api.nvim_set_keymap('n', '<Esc>[91;10u', ':echo "Hyper+X pressed"<CR>', { noremap = true, silent = true })
