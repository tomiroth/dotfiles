vim.g.mapleader = " "
vim.keymap.set("n", "<leader>dd", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", vim.cmd.Neogit)
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>")

-- Map <Leader>y to yank the current line to the system clipboard
vim.api.nvim_set_keymap('n', '<Leader>yy', '"+yy', { noremap = true, silent = true })
-- Map <leader>y to yank current selecttion to system clipboard
vim.api.nvim_set_keymap('v', '<Leader>yy', '"+y', { noremap = true, silent = true })
-- Map <Leader>y to paste the current line to the system clipboard
vim.api.nvim_set_keymap('n', '<Leader>yp', '"+p', { noremap = true, silent = true })
-- Map <leader>y to paste current selecttion to system clipboard
vim.api.nvim_set_keymap('v', '<Leader>yp', '"+p', { noremap = true, silent = true })

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

-- Dap
vim.keymap.set("n", "<leader>dc", ':lua require"dap".continue()<CR>')
vim.keymap.set("n", "<leader>ds", ':lua require"dap".stop()<CR>')
vim.keymap.set("n", "<leader>db", ':lua require"dap".toggle_breakpoint()<CR>')
vim.keymap.set("n", "<leader>dn", ':lua require"dap".step_over()<CR>')
vim.keymap.set("n", "<leader>di", ':lua require"dap".step_into()<CR>')
vim.keymap.set("n", "<leader>do", ':lua require"dap".step_out()<CR>')
vim.keymap.set("n", "<leader>dr", ':lua require"dap".repl.toggle()<CR>')

local widgets = require("dap.ui.widgets")

-- local function scopes_sidebar()
--   local my_sidebar = widgets.sidebar(widgets.scopes)
--   my_sidebar.open()
-- end

vim.keymap.set('n', '<leader>dv', function ()
  local my_sidebar = widgets.sidebar(widgets.scopes)
  my_sidebar.open()
end)
