local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {desc = "Find Files"})
vim.keymap.set('n', '<C-f>', builtin.find_files, {desc = "Find Files"})
vim.keymap.set('n', '<leader>ps', builtin.live_grep, {desc = "Grep Files"})
vim.keymap.set('n', '<leader>pg', builtin.git_files, {desc = "Git Files"})
vim.keymap.set('n', '<leader>pb', builtin.buffers, {desc = "Buffers"})
vim.keymap.set('n', '<C-b>', builtin.buffers, {desc = "Buffers"})
vim.keymap.set('n', '<leader>ph', builtin.help_tags, {desc = "Telescope Help Tags"})


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
