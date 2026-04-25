vim.g.mapleader = " "
vim.keymap.set("n", "<leader>dd", vim.cmd.Ex, {desc = "Explore Directory of current buffer"})
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit, {desc = "Neo Git"})
-- Quit buffer
vim.api.nvim_set_keymap('n', '<leader>qq', ':q<CR>', { noremap = true, silent = true, desc = "Quit buffer" })
-- Go to normal mode and save
vim.api.nvim_set_keymap('i', 'jf', '<Esc>:w<CR>', { noremap = false, silent = true })
-- Go to normal mode 'jj' and 'jk'
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true, silent = true })

-- Search and replace under word.
vim.api.nvim_set_keymap('n', '<leader>s', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', { noremap = true, silent = true, desc = "replace all occurrences of current symbol." })

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

-- Quickfix navigation
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<leader>qj', ':cnext<CR>', opts)     -- Next quickfix item
vim.api.nvim_set_keymap('n', '<leader>qk', ':cprev<CR>', opts)     -- Previous quickfix item
vim.api.nvim_set_keymap('n', '<leader>qo', ':copen<CR>', opts)   -- Open quickfix
vim.api.nvim_set_keymap('n', '<leader>qc', ':cclose<CR>', opts)  -- Close quickfix
vim.api.nvim_set_keymap('n', '<leader>qf', ':cfirst<CR>', opts)  -- First item
vim.api.nvim_set_keymap('n', '<leader>ql', ':clast<CR>', opts)   -- Last item
vim.api.nvim_set_keymap('n', '<leader>qq', ':cwindow<CR>', opts) -- Toggle open if items exist


-- local harpoon = require("harpoon")
--
-- -- REQUIRED
-- harpoon:setup()
-- -- REQUIRED
--
-- vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
-- vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
--
-- vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
-- vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
-- vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
-- vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)
--
-- -- Toggle previous & next buffers stored within Harpoon list
-- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
-- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

-- local wk = require("which-key")
-- wk.add({
--   { "<leader>p", group = "Project" }, -- group
--   { "<leader>b", group = "Buffers" }, -- group
--   { "<leader>d", group = "Dir" }, -- group
--   { "<leader>h", group = "Hop" }, -- group
--   { "<leader>v", group = "LSP" }, -- group
-- })


-- Copilot
vim.keymap.set('i', '<C-F>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.keymap.set('i', '<C-D>', '<Plug>(copilot-accept-word)')
vim.g.copilot_no_tab_map = true

-- lua snip
-- local ls = require("luasnip");
-- vim.keymap.set({"i"}, "<Tab>", function() ls.expand() end, {silent = true})
-- vim.keymap.set({"i", "s"}, "<S-Tab>", function() ls.jump(1) end, {silent = true})

