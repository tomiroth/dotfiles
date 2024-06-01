vim.g.mapleader = " "
vim.keymap.set("n", "<leader>dd", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit)
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>")


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

-- Todo: Work out how to use the hyper key for binding.
vim.keymap.set("n", "<Esc>[91;10u", vim.cmd.Neogit)


-- vim.api.nvim_set_keymap('n', '<Esc>[91;10u', ':echo "Hyper+X pressed"<CR>', { noremap = true, silent = true })

-- Buffer navigation
vim.keymap.set("n", "<leader>bj", vim.cmd.bn)
vim.keymap.set("n", "<leader>bk", vim.cmd.bp)
vim.keymap.set("n", "<leader>bx", vim.cmd.bd)

-- Harpoon
local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<leader>j", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>k", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>l", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>;", function() harpoon:list():select(4) end)




local widgets = require("dap.ui.widgets")

-- local function scopes_sidebar()
--   local my_sidebar = widgets.sidebar(widgets.scopes)
--   my_sidebar.open()
-- end

-- vim.keymap.set('n', '<leader>dv', function ()
--   local my_sidebar = widgets.sidebar(widgets.scopes)
--   my_sidebar.open()
-- end)


local wk = require("which-key")
-- Dap
wk.register({
 d = {
   d = {":Ex <CR>", "Open Directory"},
   c = {":lua require'dap'.continue()<CR>", "Dap Continue"},
   s = {":lua require'dap'.stop()<CR>", "Dap Stop"},
   b = {":lua require'dap'.toggle_breakpoint()<CR>", "Dap Toggle Breakpoint"},
   B = {":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", "Dap Set Breakpoint"},
   n = {":lua require'dap'.step_over()<CR>", "Dap Step Over"},
   i = {":lua require'dap'.step_into()<CR>", "Dap Step Into"},
   o = {":lua require'dap'.step_out()<CR>", "Dap Step Out"},
   r = {":lua require'dap'.repl.open()<CR>", "Dap Open Repl"},
   v = { function() require('dapui').toggle() end, "Dap Toggle UI" },


   j = {vim.diagnostic.goto_next, "Diagnostics Next"},
   k = {vim.diagnostic.goto_prev, "Diagnostics Previous"},
   f = { "<cmd>Telescope diagnostics<cr>", "Diagnostics List" },

   ["1"] = "which_key_ignore",  -- special label to hide it in the popup
 },
}, { prefix = "<leader>" })

wk.register(mappings, opts)
