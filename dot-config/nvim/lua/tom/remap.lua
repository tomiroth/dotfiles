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


-- Open file in git hub
vim.api.nvim_set_keymap('n', '<leader>pG', '! gh browse %<CR>', opts)

-- Git log with full patch for current file
vim.keymap.set("n", "<leader>gl", ":term git log -p %<CR>", { noremap = true, silent = true, desc = "Git log patch history for file" })

-- Open current file as it was at a given commit, in a scratch (non-savable) buffer
local function git_show_at_commit()
  local commit = vim.fn.input("Commit hash: ")
  if commit == "" then
    return
  end

  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repository", vim.log.levels.ERROR)
    return
  end

  local rel_path = vim.fn.expand("%:p"):sub(#git_root + 2)
  local content = vim.fn.systemlist({ "git", "-C", git_root, "show", commit .. ":" .. rel_path })
  if vim.v.shell_error ~= 0 then
    vim.notify(table.concat(content, "\n"), vim.log.levels.ERROR)
    return
  end

  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
  pcall(vim.api.nvim_buf_set_name, 0, commit .. ":" .. rel_path)
  vim.cmd("filetype detect")
end

vim.keymap.set("n", "<leader>gs", git_show_at_commit, { desc = "Open current file at a given commit hash (scratch buffer)" })

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

