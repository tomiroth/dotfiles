local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {desc = "Find Files"})
vim.keymap.set('n', '<C-f>', builtin.find_files, {desc = "Find Files"})
vim.keymap.set('n', '<leader>ps', builtin.live_grep, {desc = "Grep Files"})
vim.keymap.set('n', '<leader>pg', builtin.git_files, {desc = "Git Files"})
vim.keymap.set('n', '<leader>pb', builtin.buffers, {desc = "Buffers"})
vim.keymap.set('n', '<C-b>', builtin.buffers, {desc = "Buffers"})
vim.keymap.set('n', '<leader>ph', builtin.help_tags, {desc = "Telescope Help Tags"})
vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>", {desc = "Find Directories"})
vim.api.nvim_set_keymap('n', '<leader>pF', ':lua require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })<CR>', { noremap = true, silent = true, desc = "Find Files Current Directory" })
vim.api.nvim_set_keymap('n', '<leader>vS', ':Telescope lsp_document_symbols<CR>', { noremap = true, silent = true, desc = "List File Symbols" })
vim.api.nvim_set_keymap('n', '<leader>vm', ':Telescope lsp_document_symbols symbols=method<CR>', { noremap = true, silent = true, desc = "List File Symbols" })



require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      n = {
    	  ['<c-d>'] = require('telescope.actions').delete_buffer
      }, -- n
      i = {
        ["<C-h>"] = "which_key",
        ['<c-d>'] = require('telescope.actions').delete_buffer
      } -- i
    } -- mappings
  }, -- defaults
} -- telescope setup
