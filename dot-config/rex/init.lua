-- Migrated from tmux, Ghostty and Alacritty.

-- tmux (~/.tmux.conf), prefix ctrl+b
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
rex.bind("ctrl+b>r", "client.config.reload")
rex.bind("ctrl+b>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>z", "pane.zoom")
-- Close the pane, or the whole tab when it's the tab's last pane.
local function panes_in_tab(block_id)
  local view = rex.session.view{}
  if not view then return nil end
  for _, win in ipairs(view.windows or {}) do
    local count, found = 0, false
    for _, layer in ipairs(win.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        count = count + 1
        if b.block_id == block_id then found = true end
      end
    end
    if found then return count end
  end
end

rex.action{
  name = "close_pane_or_tab",
  title = "Close Pane (or Tab if Last)",
  category = "Pane",
  run = function(ctx)
    local n = ctx.block_id and panes_in_tab(ctx.block_id)
    if n == 1 then
      rex.client.queue("client.tab.close")
    else
      rex.client.queue("pane.close")
    end
  end,
}
rex.bind("ctrl+b>x", "close_pane_or_tab")

-- tmux windows -> Rex tabs (Rex counts tabs from 1)
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>n", "client.tab.next")
rex.bind("ctrl+b>,", "client.tab.rename")
for i = 1, 9 do
  rex.bind("ctrl+b>" .. i, "client.tab.goto", { index = i })
end

-- tmux sessions
--
-- Rex has no "last session", so remember it ourselves. The app doesn't tell
-- the server which session it's showing; we only learn it from ctx.session_id
-- when one of our actions runs. Session-switching keys go through
-- "tracked_switch" so the session you leave is recorded before you leave it.
local cur_session, last_session

local function track(ctx)
  local sid = ctx.session_id
  if sid and sid ~= cur_session then
    last_session = cur_session
    cur_session = sid
  end
end

rex.action{
  name = "tracked_switch",
  title = "Switch Session (remembering this one)",
  category = "Session",
  args = { action = "string" },
  run = function(ctx, args)
    track(ctx)
    rex.client.queue(args.action)
  end,
}

rex.action{
  name = "last_session",
  title = "Go to Last Session",
  category = "Session",
  run = function(ctx)
    track(ctx)
    local target = last_session
    if not target or target == cur_session then return end
    if not rex.session.view{ session_id = target } then
      last_session = nil -- it was closed
      return
    end
    last_session, cur_session = cur_session, target
    rex.client.queue("session.select", { session_id = target })
  end,
}

rex.bind("ctrl+b>p", "last_session")
rex.bind("ctrl+b>s", "tracked_switch", { action = "session.switch" })
rex.bind("ctrl+b>shift+9", "tracked_switch", { action = "session.previous" }) -- (
rex.bind("ctrl+b>shift+0", "tracked_switch", { action = "session.next" })     -- )
rex.bind("cmd+k", "tracked_switch", { action = "session.switch" })
rex.bind("cmd+p", "tracked_switch", { action = "pane.go_to" })
rex.bind("shift+cmd+n", "tracked_switch", { action = "session.new" })
rex.bind("ctrl+b>shift+4", "session.rename")   -- $

-- ctrl+b b hides/shows the tab bar. The setting only cycles or takes a value,
-- so remember which way we last set it (assumes "shown" after a reload).
local tab_bar_hidden = false
rex.action{
  name = "toggle_tab_bar",
  title = "Hide or Show Tab Bar",
  category = "View",
  run = function()
    tab_bar_hidden = not tab_bar_hidden
    rex.client.queue("client.setting.interface.toolbar.auto_hide_toolbar",
      { value = tab_bar_hidden and "hidden" or "always_show" })
  end,
}
rex.bind("ctrl+b>b", "toggle_tab_bar")

-- Popups, like tmux display-popup: a floating pane in the current pane's
-- directory that closes when its program exits.
local function current_dir(ctx)
  if not ctx.block_id then return nil end
  local r = rex.block.call("com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
  if not (r and r.pwd) then return nil end
  local path = r.pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- Floating layers opened by the popup helpers below can be dismissed with
-- Escape. Track just those layers, so Escape keeps its normal meaning (and
-- reaches Claude, less, nvim, etc.) everywhere else.
local esc_popup_layers = {}

local function popup(ctx, command)
  local result = rex.session.new_layer{
    session_id = ctx.session_id,
    bounds = { 0.15, 0.15, 0.7, 0.7 },
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      options = { command = command, cwd = current_dir(ctx) },
    },
  }
  if result and result.layer_id then
    esc_popup_layers[result.layer_id] = true
  end
  return result
end

-- Close a tracked popup only when it has focus. Returning false lets Escape
-- pass through to the focused program in every other case.
rex.bind("escape", function(ctx)
  local session_id = ctx.session_id
  if not session_id then return false end

  local view = rex.session.view{ session_id = session_id }
  if not view then return false end

  local focused = ctx.block_id
  if not focused then
    for _, win in ipairs(view.windows or {}) do
      if win.window_id == view.active_window_id then
        focused = win.focused_block_id
        break
      end
    end
  end
  if not focused then return false end

  for _, win in ipairs(view.windows or {}) do
    for _, layer in ipairs(win.layers or {}) do
      local layer_id = layer.layer_id
      if layer.kind == "floating" and esc_popup_layers[layer_id] then
        for _, block in ipairs(layer.blocks or {}) do
          if block.block_id == focused then
            esc_popup_layers[layer_id] = nil
            rex.session.close_layer{ session_id = session_id, layer_id = layer_id }
            return true
          end
        end
      end
    end
  end
  return false
end)

rex.action{
  name = "claude_usage_popup",
  title = "Claude Code Usage (popup)",
  category = "Claude",
  run = function(ctx) return popup(ctx, { "claude", "/usage" }) end,
}
rex.bind("ctrl+b>u", "claude_usage_popup")

rex.action{
  name = "claude_commit_popup",
  title = "Commit Staged Files with Claude (popup)",
  category = "Claude",
  run = function(ctx)
    return popup(ctx, { "claude", "--permission-mode", "manual", "--model", "haiku",
      "commit staged files" })
  end,
}
rex.bind("ctrl+b>shift+s", "claude_commit_popup")

-- ctrl+b R : pick from the running agents (pi, claude, codex, ...) across all
-- sessions and jump to the one chosen. Uses Rex's built-in picker (jk/enter).
local agent_names = { pi = true, claude = true, codex = true, gemini = true,
  opencode = true, aider = true, amp = true }

rex.action{
  name = "agents_popup",
  title = "Jump to Running Agent",
  category = "Agent",
  run = function(ctx)
    local items = {}
    local lookup = {}
    local sessions = (rex.call("session.list") or {}).sessions or {}
    for _, s in ipairs(sessions) do
      local view = rex.session.view{ session_id = s.session_id }
      if view then
        for _, win in ipairs(view.windows or {}) do
          for _, layer in ipairs(win.layers or {}) do
            for _, block in ipairs(layer.blocks or {}) do
              if block.creator_name == "com.superlogical.terminal" then
                local status = rex.block.call("com.superlogical.terminal", "program_status",
                  { block_id = block.block_id })
                local records = (status and status.records) or {}
                local foreground_agent
                if #records == 0 then
                  local proc = rex.block.call("com.superlogical.terminal", "process",
                    { block_id = block.block_id })
                  local fg = proc and proc.foreground
                  local base = fg and (fg.argv0 or fg.name)
                  base = base and base:match("([^/]+)$")
                  if base and agent_names[base] then foreground_agent = base end
                end
                local to_add = {}
                if #records > 0 then
                  for _, rec in ipairs(records) do
                    table.insert(to_add, rec)
                  end
                elseif foreground_agent then
                  table.insert(to_add, { app = foreground_agent, state = "running" })
                end
                for _, rec in ipairs(to_add) do
                  local agent = rec.app or rec.effective_app or foreground_agent or "agent"
                  local state = rec.state or "running"
                  local proc = rex.block.call("com.superlogical.terminal", "process",
                    { block_id = block.block_id })
                  local cwd = (proc and proc.foreground and proc.foreground.cwd) or ""
                  local label = string.format("%s | %s (%s) | %s",
                    s.label or s.session_id, agent, state, cwd)
                  local composite = s.session_id .. "|" .. block.block_id .. "|" .. label
                  table.insert(items, { id = composite })
                  lookup[composite] = { session_id = s.session_id, block_id = block.block_id }
                end
              end
            end
          end
        end
      end
    end

    rex.log("info", "agents_popup: found " .. #items .. " agents")
    if #items == 0 then
      rex.log("warn", "no running agents found")
      return
    end

    local choice = rex.ui.pick{ title = "Running agents", items = items }
    local selected
    if type(choice) == "table" then
      if type(choice.ids) == "table" and choice.ids[1] then
        selected = choice.ids[1]
      elseif type(choice.id) == "string" then
        selected = choice.id
      elseif type(choice.text) == "string" then
        selected = choice.text
      end
    elseif type(choice) == "string" then
      selected = choice
    end
    if not selected then return end

    local sid, bid = selected:match("^([^|]+)|([^|]+)|")
    if not sid or not bid then return end

    local oka, erra = pcall(rex.call, "session.attach", { session_id = sid })
    rex.log("info", "agents_popup: attach " .. tostring(oka) .. " " .. tostring(erra))
    local okf, errf = pcall(rex.call, "session.focus_block", { session_id = sid, block_id = bid })
    rex.log("info", "agents_popup: focus " .. tostring(okf) .. " " .. tostring(errf))
    rex.client.queue("session.select", { session_id = sid })
  end,
}
rex.bind("ctrl+b>shift+r", "agents_popup")

-- ctrl+b [ : tmux-style copy mode, using Rex's built-in vim-style copy mode.
-- h/j/k/l move, / and ? search scrollback, v/V/C-v select, y yanks, Esc/q exits.
-- The nvim scrollback popup below remains available from the command palette.
-- A pane's rect in its window, as {x, y, w, h} fractions, from the tiled layout.
local function pane_rect(session_id, block_id)
  local view = rex.session.view{ session_id = session_id }
  if not view then return nil end
  local function find(node)
    if type(node) ~= "table" then return nil end
    if node.block_id == block_id and node.rect then return node.rect end
    for _, child in pairs(node) do
      local r = find(child)
      if r then return r end
    end
  end
  for _, win in ipairs(view.windows or {}) do
    for _, layer in ipairs(win.layers or {}) do
      if layer.kind == "tiled" then
        local r = find(layer.layout)
        if r then return r end
      end
    end
  end
end

rex.action{
  name = "scrollback_in_nvim",
  title = "Open Scrollback in Neovim (popup)",
  category = "Pane",
  run = function(ctx)
    if not ctx.block_id then return end
    -- Capture with colour codes (vt) and let scrollback.lua render them.
    -- Width: the source pane's width + 10% (room for line numbers), capped at
    -- the window, centred on the pane. Height stays at 90%.
    local x, w = 0.05, 0.9
    local rect = pane_rect(ctx.session_id, ctx.block_id)
    if rect then
      w = math.min(rect[3] * 1.1, 1)
      local centre = rect[1] + rect[3] / 2
      x = math.max(0, math.min(centre - w / 2, 1 - w))
    end
    local script = "export REX_SCROLLBACK_FILE=$(mktemp)"
      .. " && rex capture -b '" .. ctx.block_id .. "' --format vt --trim > \"$REX_SCROLLBACK_FILE\""
      .. " && nvim -c 'luafile ~/.config/rex/scrollback.lua'"
    return rex.session.new_layer{
      session_id = ctx.session_id,
      bounds = { x, 0.05, w, 0.9 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = { command = { "zsh", "-c", script }, cwd = current_dir(ctx) },
      },
    }
  end,
}
rex.bind("ctrl+b>[", "pane.copy_mode.enter")

-- ctrl+b ? shows the hand-written cheat sheet in a popup (q closes it).
-- Keep ~/.config/rex/cheatsheet.txt in step with the bindings in this file.
-- For the raw, always-current list run: rex keymap
rex.action{
  name = "keybinds_popup",
  title = "Keybind Cheat Sheet (popup)",
  category = "Help",
  run = function(ctx)
    return popup(ctx, { "less", "-R", "-S", os.getenv("HOME") .. "/.config/rex/cheatsheet.txt" })
  end,
}
rex.bind("ctrl+b>shift+/", "keybinds_popup")

-- ctrl+h/j/k/l move between panes, like vim-tmux-navigator: when the pane is
-- running (n)vim the key is passed through, and nvim moves between its own
-- splits, handing back to Rex at the edge (~/.config/nvim/after/plugin/rex_navigator.lua).
-- Elsewhere these keys no longer reach programs
-- (ctrl+h backspace, ctrl+l clear, ctrl+k kill-line, ctrl+j newline).
local function running_vim(block_id)
  local p = block_id and rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
  local fg = p and p.foreground
  if not fg then return false end
  for _, s in ipairs({ fg.name, fg.argv0, fg.invoked_path }) do
    local base = s and s:match("([^/]+)$")
    if base and (base == "nvim" or base == "vim" or base == "vi") then return true end
  end
  return false
end

rex.action{
  name = "navigate",
  title = "Navigate Pane (vim-aware)",
  category = "Pane",
  args = { key = "string", direction = "string" },
  run = function(ctx, args)
    if running_vim(ctx.block_id) then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue("pane.focus", { direction = args.direction })
    end
  end,
}
rex.bind("ctrl+h", "navigate", { key = "ctrl+h", direction = "left" })
rex.bind("ctrl+j", "navigate", { key = "ctrl+j", direction = "down" })
rex.bind("ctrl+k", "navigate", { key = "ctrl+k", direction = "up" })
rex.bind("ctrl+l", "navigate", { key = "ctrl+l", direction = "right" })
rex.bind("alt+shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("alt+shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("alt+shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("alt+shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("alt+j", "pane.split", { direction = "down" })
rex.bind("alt+k", "pane.split", { direction = "up" })
rex.bind("alt+l", "pane.split", { direction = "right" })
rex.bind("alt+shift+g", "pane.split", { direction = "right" })
rex.bind("alt+h", "pane.split", { direction = "left" })
rex.bind("alt+x", "pane.close")

-- Ghostty (~/.config/ghostty/config)
rex.bind("ctrl+shift+cmd+j", "client.font.increase")
rex.bind("ctrl+shift+cmd+k", "client.font.decrease")

-- Alacritty (~/.config/alacritty/alacritty.toml)
rex.bind("alt+3", "pane.send_key", { key = "shift+3" })
rex.bind("alt+0", "client.font.increase")
rex.bind("alt+9", "client.font.decrease")
rex.bind("alt+8", "client.font.reset")
