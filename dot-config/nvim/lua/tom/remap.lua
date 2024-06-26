vim.g.mapleader = " "
vim.keymap.set("n", "<leader>dd", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit)
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>")
vim.api.nvim_set_keymap('n', '<leader>pF', ':lua require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })<CR>', { noremap = true, silent = true })

-- Quit buffer
vim.api.nvim_set_keymap('n', '<leader>qq', ':q<CR>', { noremap = true, silent = true })
-- Wrtie and quit buffer
vim.api.nvim_set_keymap('n', '<leader>wq', ':wq<CR>', { noremap = true, silent = true })
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
   a = {vim.lsp.buf.code_action, "Diagnostics Previous"},
   f = { "<cmd>Telescope diagnostics<cr>", "Diagnostics List" },

   ["1"] = "which_key_ignore",  -- special label to hide it in the popup
 },
}, { prefix = "<leader>" })

wk.register(mappings, opts)

-- Copilot
vim.keymap.set('i', '<C-K>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.keymap.set('i', '<C-J>', '<Plug>(copilot-accept-word)')
vim.g.copilot_no_tab_map = true
