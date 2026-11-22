-- vim-tmux-navigator for Rex: ctrl+h/j/k/l move between nvim splits, and at
-- the edge move focus to the neighbouring Rex pane. Only active inside Rex
-- (and not inside tmux, where vim-tmux-navigator keeps working as before).
-- The Rex side lives in ~/.config/rex/init.lua (the "navigate" action).
if not vim.env.REX_BLOCK or vim.env.TMUX then return end

local moves = {
  h = { "h", "left" },
  j = { "j", "down" },
  k = { "k", "up" },
  l = { "l", "right" },
}

local function navigate(m)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. m[1])
  if vim.api.nvim_get_current_win() == win then
    vim.system({ "rex", "focus", m[2], "-s", vim.env.REX_SESSION })
    return false
  end
  return true
end

for key, m in pairs(moves) do
  local lhs = "<C-" .. key .. ">"
  local opts = { silent = true, desc = "Rex navigate " .. m[2] }

  vim.keymap.set("n", lhs, function()
    navigate(m)
  end, opts)

  -- Move windows from insert mode and carry on typing in the destination
  -- split. startinsert has to wait until this key's handling has finished.
  -- At the edge Rex takes focus, so there is no split to resume in.
  -- This intentionally overrides lsp.lua's insert-mode <C-H> signature help.
  vim.keymap.set("i", lhs, function()
    if navigate(m) then
      vim.schedule(function() vim.cmd.startinsert() end)
    end
  end, opts)
end
