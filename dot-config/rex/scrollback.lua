-- Loaded by nvim for Rex's ctrl+b [ popup (see init.lua: scrollback_in_nvim).
-- Renders a pane's captured scrollback, colour codes included, in a terminal
-- buffer with no process behind it, so normal-mode motions, search and yank work.
local path = vim.env.REX_SCROLLBACK_FILE
local f = path and io.open(path, "rb")
if not f then return end
local data = f:read("*a")
f:close()
os.remove(path)

vim.o.scrollback = 100000 -- the maximum; the default 10000 would drop older lines
local buf = vim.api.nvim_get_current_buf()
local chan = vim.api.nvim_open_term(buf, {})
vim.api.nvim_chan_send(chan, data)
vim.bo[buf].modified = false

-- Output is drawn asynchronously; jump to the bottom once it has landed.
-- nvim turns line numbers off in terminal buffers (its TermOpen autocmd), so
-- turn them back on, matching the relative numbering from your config.
vim.defer_fn(function()
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.cmd("normal! G")
end, 50)
