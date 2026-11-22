local function pick(builtin, opts)
  return function()
    require('tom.telescope').load()
    require('telescope.builtin')[builtin](opts or {})
  end
end

vim.keymap.set('n', '<leader>pf', pick('find_files'), { desc = "Find Files" })
vim.keymap.set('n', '<C-f>', pick('find_files'), { desc = "Find Files" })
vim.keymap.set('n', '<leader>ps', pick('live_grep'), { desc = "Grep Files" })
vim.keymap.set('n', '<leader>pg', pick('git_files'), { desc = "Git Files" })
vim.keymap.set('n', '<leader>pb', pick('buffers'), { desc = "Buffers" })
vim.keymap.set('n', '<C-b>', pick('buffers'), { desc = "Buffers" })
vim.keymap.set('n', '<leader>ph', pick('help_tags'), { desc = "Telescope Help Tags" })
vim.keymap.set('n', '<leader>pF', function()
  require('tom.telescope').load()
  require('telescope.builtin').find_files({ cwd = vim.fn.expand('%:p:h') })
end, { desc = "Find Files Current Directory" })
vim.keymap.set('n', '<leader>vS', pick('lsp_document_symbols'), { desc = "List File Symbols" })
vim.keymap.set('n', '<leader>vm', pick('lsp_document_symbols', { symbols = 'method' }), { desc = "List File Methods" })

vim.keymap.set('n', '<leader>pd', "<cmd>lua require('tom.telescope').find_directories()<CR>", { desc = "Find Directories" })
vim.keymap.set('n', '<leader>pa', "<cmd>lua require('tom.telescope').live_grep_current_dir()<CR>", { desc = "Live Grep (Current Dir)" })
