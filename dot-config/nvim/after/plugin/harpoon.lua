local function harpoon()
  return require('tom.harpoon').load()
end

vim.keymap.set("n", "<leader>a", function() harpoon():list():add() end)
vim.keymap.set("n", "<C-e>", function()
  local h = harpoon()
  h.ui:toggle_quick_menu(h:list())
end)

vim.keymap.set("n", "<leader>j", function() harpoon():list():select(1) end)
vim.keymap.set("n", "<leader>k", function() harpoon():list():select(2) end)
vim.keymap.set("n", "<leader>l", function() harpoon():list():select(3) end)
vim.keymap.set("n", "<leader>;", function() harpoon():list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-P>", function() harpoon():list():prev() end)
vim.keymap.set("n", "<C-S-N>", function() harpoon():list():next() end)
