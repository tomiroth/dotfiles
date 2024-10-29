vim.g.mapleader = " "
vim.keymap.set("n", "<leader>dd", vim.cmd.Ex, {desc = "Explore Directory of current buffer"})
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit, {desc = "Neo Git"})
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>", {desc = "Find Directories"})
vim.api.nvim_set_keymap('n', '<leader>pF', ':lua require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })<CR>', { noremap = true, silent = true, desc = "Find Files Current Directory" })
-- Quit buffer
vim.api.nvim_set_keymap('n', '<leader>qq', ':q<CR>', { noremap = true, silent = true, desc = "Quit buffer" })
-- Wrtie and quit buffer
vim.api.nvim_set_keymap('n', '<leader>wq', ':wq<CR>', { noremap = true, silent = true, desc = "Write file" })
-- Go to normal mode and save
vim.api.nvim_set_keymap('i', 'jf', '<Esc>:w<CR>', { noremap = false, silent = true })
-- Go to normal mode 'jj' and 'jk'
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true, silent = true })

-- Search and replace under word.
vim.api.nvim_set_keymap('n', '<leader>s', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', { noremap = true, silent = true })

-- Map Ctrl-x Ctrl-s to save the file from insert mode
vim.api.nvim_set_keymap('i', '<C-x><C-s>', '<Esc>:w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-x><C-s>', ':w<CR>', { noremap = true, silent = true })

-- relative line numbers toggle 
vim.api.nvim_set_keymap('n', '<leader>n', ':set relativenumber!<CR>', { noremap = true, silent = true })

--- To System Clipboard
-- Yank to system clipboard in normal mode
vim.api.nvim_set_keymap('n', 'y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'yy', '"+yy', { noremap = true, silent = true })

-- Yank to system clipboard in visual mode
vim.api.nvim_set_keymap('v', 'y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'Y', '"+y', { noremap = true, silent = true })

-- Paste from system clipboard in normal mode
vim.api.nvim_set_keymap('n', 'p', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'P', '"+P', { noremap = true, silent = true })

-- Paste from system clipboard in visual mode
vim.api.nvim_set_keymap('v', 'p', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'P', '"+P', { noremap = true, silent = true })

-- Yank to system clipboard in operator-pending mode
vim.api.nvim_set_keymap('x', 'y', '"+y', { noremap = true, silent = true })

-- Delete to system clipboard in normal mode
vim.api.nvim_set_keymap('n', 'd', '"+d', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dd', '"+dd', { noremap = true, silent = true })

-- Delete to system clipboard in visual mode
vim.api.nvim_set_keymap('v', 'd', '"+d', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'D', '"+d', { noremap = true, silent = true })

-- Delete to system clipboard in operator-pending mode
vim.api.nvim_set_keymap('x', 'd', '"+d', { noremap = true, silent = true })
---

-- Buffer navigation
vim.keymap.set("n", "<leader>bj", vim.cmd.bn, {desc = "Next Buffer"})
vim.keymap.set("n", "<leader>bk", vim.cmd.bp, {desc = "Previous Buffer"})
vim.keymap.set("n", "<leader>bx", vim.cmd.bd, {desc = "Delete Buffer"})

-- Harpoon
local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, {desc = "Add to harpoon"})
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, {desc = "View harpoon list"})

vim.keymap.set("n", "<leader>j", function() harpoon:list():select(1) end, {desc = "Harpoon Buffer 1"})
vim.keymap.set("n", "<leader>k", function() harpoon:list():select(2) end, {desc = "Harpoon Buffer 2"})
vim.keymap.set("n", "<leader>l", function() harpoon:list():select(3) end, {desc = "Harpoon Buffer 3"})
vim.keymap.set("n", "<leader>;", function() harpoon:list():select(4) end, {desc = "Harpoon Buffer 4"})

local wk = require("which-key")
wk.add({
  { "<leader>p", group = "Project" }, -- group
  { "<leader>b", group = "Buffers" }, -- group
  { "<leader>d", group = "Dir" }, -- group
  { "<leader>h", group = "Hop" }, -- group
  { "<leader>v", group = "LSP" }, -- group
})


-- Copilot
vim.keymap.set('i', '<C-F>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.keymap.set('i', '<C-D>', '<Plug>(copilot-accept-word)')
vim.g.copilot_no_tab_map = true

-- lua snip
local ls = require("luasnip");
vim.keymap.set({"i"}, "<Tab>", function() ls.expand() end, {silent = true})
vim.keymap.set({"i", "s"}, "<S-Tab>", function() ls.jump(1) end, {silent = true})

