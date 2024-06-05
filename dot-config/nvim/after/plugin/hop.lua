local hop = require('hop')
local directions = require('hop.hint').HintDirection
hop.setup { keys = 'hjkletovxqpdygfbzcisuran' }
vim.keymap.set('', '<leader>hf', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
end, {remap=true})
vim.keymap.set('', '<leader>hF', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
end, {remap=true})
vim.keymap.set('', '<leader>ht', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
end, {remap=true})
vim.keymap.set('', '<leader>hT', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
end, {remap=true})
vim.keymap.set('', '<leader>.', function()
  hop.hint_char1({ current_line_only = false, multi_windows = true })
end, {remap=true})

