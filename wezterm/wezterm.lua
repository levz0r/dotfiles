local wezterm = require 'wezterm'
local act = wezterm.action

local config = {
  -- RTL / Hebrew
  bidi_enabled = true,
  bidi_direction = 'AutoLeftToRight',

  -- Appearance — Ghostty default palette
  colors = {
    background = '#282C34',
    foreground = '#FFFFFF',
    cursor_bg  = '#FFFFFF',
    cursor_fg  = '#282C34',
    cursor_border = '#FFFFFF',
    selection_bg = '#3E4451',
    selection_fg = '#FFFFFF',
    ansi = {
      '#1D1F21', '#CC6666', '#B5BD68', '#F0C674',
      '#81A2BE', '#B294BB', '#8ABEB7', '#C5C8C6',
    },
    brights = {
      '#666666', '#D54E53', '#B9CA4A', '#E7C547',
      '#7AA6DA', '#C397D8', '#70C0B1', '#EAEAEA',
    },
  },
  font = wezterm.font_with_fallback {
    'JetBrains Mono',
    'Symbols Nerd Font Mono',  -- icons / powerline glyphs
    'Miriam Mono CLM',
    'Menlo',
    'Noto Sans Hebrew',
  },
  font_size = 14.0,
  line_height = 1.1,

  -- Cursor
  default_cursor_style = 'BlinkingBar',
  cursor_blink_rate = 500,
  cursor_blink_ease_in  = 'EaseOut',
  cursor_blink_ease_out = 'EaseIn',

  window_background_opacity = 0.97,
  macos_window_background_blur = 20,
  window_decorations = 'TITLE | RESIZE',
  window_padding = { left = 12, right = 12, top = 8, bottom = 8 },

  -- Tabs — retro bar (more flexible) at the top
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = false,
  tab_max_width = 22,
  show_new_tab_button_in_tab_bar = false,

  -- Behavior
  scrollback_lines = 50000,
  send_composed_key_when_left_alt_is_pressed = false,
  send_composed_key_when_right_alt_is_pressed = true,  -- keep ⌥ for Hebrew/special chars on right Alt
  audible_bell = 'Disabled',
  notification_handling = 'AlwaysShow',
  adjust_window_size_when_changing_font_size = false,

  -- Mac-style word navigation
  keys = {
    { key = 'LeftArrow',  mods = 'OPT',       action = act.SendString '\x1bb' },
    { key = 'RightArrow', mods = 'OPT',       action = act.SendString '\x1bf' },
    { key = 'LeftArrow',  mods = 'CMD',       action = act.SendString '\x01' },
    { key = 'RightArrow', mods = 'CMD',       action = act.SendString '\x05' },
    { key = 'Backspace',  mods = 'OPT',       action = act.SendString '\x17' },
    { key = 'Backspace',  mods = 'CMD',       action = act.SendString '\x15' },
    { key = 'k',          mods = 'CMD',       action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'd',          mods = 'CMD',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd',          mods = 'CMD|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
    { key = 'w',          mods = 'CMD',       action = act.CloseCurrentPane { confirm = true } },

    -- Toggle to last-used tab (MRU)
    { key = 'Tab',        mods = 'CTRL',       action = act.ActivateLastTab },
    { key = 'Tab',        mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },

    -- Quick-select: hit ⌘⇧Space, type the letters next to a URL/path to copy/open it
    { key = 'Space',      mods = 'CMD|SHIFT', action = act.QuickSelect },
    -- Open URL under selection
    { key = 'o',          mods = 'CMD|SHIFT', action = act.QuickSelectArgs {
        label = 'open url',
        patterns = { 'https?://\\S+' },
        action = wezterm.action_callback(function(window, pane)
          local url = window:get_selection_text_for_pane(pane)
          if url and #url > 0 then wezterm.open_with(url) end
        end),
      },
    },
  },

  mouse_bindings = {
    -- ⌘+click opens hyperlinks (macOS convention)
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CMD',
      action = act.OpenLinkAtMouseCursor,
    },
    -- Suppress text selection on ⌘+down so the click doesn't drag-select
    {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CMD',
      action = act.Nop,
    },
  },
}

-- Bell → macOS notification via osascript (WezTerm isn't registered with NotificationCenter on macOS)
wezterm.on('bell', function(_window, pane)
  local title = (pane:get_title() or 'shell'):gsub('"', '\\"')
  wezterm.background_child_process {
    'osascript', '-e',
    'display notification "Done in ' .. title .. '" with title "WezTerm" sound name "Glass"',
  }
end)

-- =====================================================================
-- Custom tab bar: powerline tabs with process-aware icons + system stats
-- =====================================================================

-- Powerline glyphs (Nerd Font)
local SOLID_LEFT  = ''  -- U+E0B0
local SOLID_RIGHT = ''  -- U+E0B2

-- Tokyo-night-ish accent colors layered over the Ghostty palette
local C = {
  bar_bg     = '#1D1F21',
  active_bg  = '#7AA6DA',  -- bright blue
  active_fg  = '#1D1F21',
  inactive_bg= '#2C313A',
  inactive_fg= '#9DA5B4',
  seg_bg     = '#2C313A',
  seg_fg     = '#C5C8C6',
  bat_ok     = '#B9CA4A',
  bat_warn   = '#E7C547',
  bat_crit   = '#D54E53',
  cpu        = '#C397D8',
  mem        = '#70C0B1',
  clock      = '#7AA6DA',
}

config.colors.tab_bar = {
  background = C.bar_bg,
  active_tab          = { bg_color = C.active_bg,   fg_color = C.active_fg,   intensity = 'Bold' },
  inactive_tab        = { bg_color = C.inactive_bg, fg_color = C.inactive_fg },
  inactive_tab_hover  = { bg_color = '#3E4451',     fg_color = '#FFFFFF', italic = false },
  new_tab             = { bg_color = C.bar_bg,      fg_color = C.inactive_fg },
  new_tab_hover       = { bg_color = '#3E4451',     fg_color = '#FFFFFF' },
}

-- Map known process names to Nerd Font icons
-- All Material Design icons (md-* in Symbols Nerd Font Mono)
local PROC_ICONS = {
  ['nvim']     = '󰈚 ',  -- file-document-edit
  ['vim']      = '󰈚 ',
  ['nano']     = '󰈚 ',
  ['node']     = '󰎙 ',  -- nodejs
  ['npm']      = '󰎙 ',
  ['pnpm']     = '󰎙 ',
  ['bun']      = '󰎙 ',
  ['python']   = '󰌠 ',  -- language-python
  ['python3']  = '󰌠 ',
  ['ruby']     = '󰴭 ',  -- language-ruby
  ['cargo']    = '󱘗 ',  -- language-rust
  ['rustc']    = '󱘗 ',
  ['go']       = '󰟓 ',  -- language-go
  ['git']      = '󰊢 ',  -- git
  ['lazygit']  = '󰊢 ',
  ['docker']   = '󰡨 ',  -- docker
  ['psql']     = '󰆼 ',  -- database
  ['mysql']    = '󰆼 ',
  ['ssh']      = '󰣀 ',  -- server-network
  ['htop']     = '󰓅 ',  -- speedometer
  ['btop']     = '󰓅 ',
  ['top']      = '󰓅 ',
  ['claude']   = '󰚩 ',  -- robot
  ['zsh']      = '󰞷 ',  -- console
  ['bash']     = '󰞷 ',
  ['fish']     = '󰞷 ',
}

local function basename(s) return (s or ''):match '([^/]+)$' or s end


local SHELLS = { zsh = true, bash = true, fish = true, sh = true, ['-zsh'] = true }

-- Detect apps WezTerm can't see via foreground_process_name (they live inside
-- the shell process tree or only announce themselves via terminal title).
local function detect_from_title(title)
  if not title or title == '' then return nil end
  if title:find 'Claude Code' or title:match '^claude' then return 'claude' end
  if title:find 'lazygit' then return 'lazygit' end
  if title:find 'btop' then return 'btop' end
  return nil
end

local function tab_proc(pane)
  local detected = detect_from_title(pane.title)
  if detected then return detected end
  local p = basename(pane.foreground_process_name)
  -- Claude Code renames its process to its version string (e.g. "2.1.121")
  if p and p:match '^v?[%d]+%.[%d]+%.[%d]+' then return 'claude' end
  return (p and #p > 0) and p or nil
end

wezterm.on('format-tab-title', function(tab, tabs, _panes, _conf, hover, _max_w)
  local pane = tab.active_pane
  local idx  = tab.tab_index + 1

  local cwd_name
  local cwd = pane.current_working_dir
  if cwd then
    local p = (cwd.file_path or tostring(cwd)):gsub('/$', '')
    cwd_name = basename(p)
  end

  local proc = tab_proc(pane)
  local label
  if proc == 'claude' then
    local t = pane.title or ''
    -- Strip "Claude Code" anywhere; strip a trailing " · 2.1.121"
    t = t:gsub('Claude Code', '')
    t = t:gsub('%s*[·•|—–-]%s*v?%d+%.%d+%.%d+[%w%.%-]*%s*$', '')
    -- Strip dirty/unread markers like "*" or "✳" used by some apps
    t = t:gsub('^[%*✳%s]+', ''):gsub('[%*✳%s]+$', '')
    t = t:gsub('^[·•|—–-]%s*', ''):gsub('%s*[·•|—–-]$', '')
    t = t:gsub('^%s+', ''):gsub('%s+$', '')
    if t == '' or t:match '^v?[%d%.]+$' then
      label = cwd_name or 'claude'
    else
      label = t
    end
  elseif proc and not SHELLS[proc] then
    label = (cwd_name and (cwd_name .. ' · ' .. proc)) or proc
  else
    label = cwd_name or 'shell'
  end

  -- Truncate overlong labels so the right-status bar stays visible
  if #label > 18 then label = label:sub(1, 17) .. '…' end

  local icon = (proc and PROC_ICONS[proc]) or ' '
  local body = idx .. ' ' .. icon .. label .. ' '

  local is_last = tab.tab_index == #tabs - 1
  local next_tab = tabs[tab.tab_index + 2]
  local next_active = next_tab and next_tab.is_active

  if tab.is_active then
    return {
      { Background = { Color = C.active_bg } },
      { Foreground = { Color = C.active_fg } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' ' .. body },
      { Background = { Color = C.bar_bg } },
      { Foreground = { Color = C.active_bg } },
      { Text = SOLID_LEFT },
    }
  else
    local sep_fg = is_last and C.bar_bg or (next_active and C.active_bg or C.inactive_bg)
    return {
      { Background = { Color = C.inactive_bg } },
      { Foreground = { Color = C.inactive_fg } },
      { Text = ' ' .. body },
      { Background = { Color = sep_fg } },
      { Foreground = { Color = C.inactive_bg } },
      { Text = SOLID_LEFT },
    }
  end
end)

-- ----- System stats (cached, refreshed every 5s) -----
local stats_cache = { load = '?', mem = '?', refreshed_at = 0 }

local function refresh_stats()
  local now = os.time()
  if now - stats_cache.refreshed_at < 5 then return end
  stats_cache.refreshed_at = now

  local _, load_out = wezterm.run_child_process { 'sysctl', '-n', 'vm.loadavg' }
  if load_out then stats_cache.load = (load_out:match '([%d%.]+)' or '?') end

  local _, mem_out = wezterm.run_child_process {
    'sh', '-c',
    [[ps -A -o %mem | awk 'NR>1 {s+=$1} END {printf "%.0f", s}']],
  }
  if mem_out then stats_cache.mem = (mem_out:gsub('%s', '') ~= '' and mem_out or '?') end
end

-- Clock face matching the wall time (12-hour, half-hour resolution)
local CLOCK_FACES = {
  ['1:00']='🕐', ['2:00']='🕑', ['3:00']='🕒', ['4:00']='🕓',
  ['5:00']='🕔', ['6:00']='🕕', ['7:00']='🕖', ['8:00']='🕗',
  ['9:00']='🕘', ['10:00']='🕙', ['11:00']='🕚', ['12:00']='🕛',
  ['1:30']='🕜', ['2:30']='🕝', ['3:30']='🕞', ['4:30']='🕟',
  ['5:30']='🕠', ['6:30']='🕡', ['7:30']='🕢', ['8:30']='🕣',
  ['9:30']='🕤', ['10:30']='🕥', ['11:30']='🕦', ['12:30']='🕧',
}
local function clock_emoji()
  local h = tonumber(wezterm.strftime '%I')   -- 1..12
  local m = tonumber(wezterm.strftime '%M')
  local mm = (m >= 15 and m < 45) and '30' or '00'
  if m >= 45 then h = (h % 12) + 1 end
  return CLOCK_FACES[h .. ':' .. mm] or '🕛'
end

local function battery_segment()
  local bats = wezterm.battery_info()
  if #bats == 0 then return nil, nil end
  local b = bats[1]
  local pct = math.floor((b.state_of_charge or 0) * 100)
  local icon
  if b.state == 'Charging' then icon = '󰂄'
  elseif pct >= 90 then icon = '󰁹'
  elseif pct >= 70 then icon = '󰂁'
  elseif pct >= 40 then icon = '󰁿'
  elseif pct >= 20 then icon = '󰁽'
  else icon = '󰁻' end
  local color = (pct < 20 and C.bat_crit) or (pct < 40 and C.bat_warn) or C.bat_ok
  return icon .. ' ' .. pct .. '%', color
end

wezterm.on('update-status', function(window, _pane)
  refresh_stats()

  local segments = {}
  local function add(text, fg)
    table.insert(segments, { text = text, fg = fg })
  end

  local bat_text, bat_color = battery_segment()
  if bat_text then add(bat_text, bat_color) end
  add('󰻠 ' .. stats_cache.load, C.cpu)
  add('󰍛 ' .. stats_cache.mem .. '%', C.mem)
  add(clock_emoji() .. ' ' .. wezterm.strftime '%H:%M', C.clock)

  -- Render with powerline-right separators
  local elements = {}
  for i, seg in ipairs(segments) do
    table.insert(elements, { Background = { Color = C.bar_bg } })
    table.insert(elements, { Foreground = { Color = C.seg_bg } })
    table.insert(elements, { Text = SOLID_RIGHT })
    table.insert(elements, { Background = { Color = C.seg_bg } })
    table.insert(elements, { Foreground = { Color = seg.fg } })
    table.insert(elements, { Text = ' ' .. seg.text .. ' ' })
  end
  window:set_right_status(wezterm.format(elements))
end)

return config
