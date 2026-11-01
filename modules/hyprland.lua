-- hyprsimple-nix's additions to Hyprland's configuration: workspace names,
-- apps on their own workspace, window groups, the i3 layout and more keys,
-- each when programs.hyprsimple turns it on.
-- hyprsimple's own config loads this file (patch 0007), after its defaults
-- and before your files in ~/.config/hypr, so your settings still win. The
-- `nix` table above it holds the settings from your NixOS configuration.

local function bind(keys, action, description)
  hl.bind(keys, action, { description = description })
end

-- ---- Workspace names --------------------------------------------------------

for number, name in ipairs(nix.names) do
  hl.workspace_rule({ workspace = tostring(number), default_name = name })
end

-- ---- Apps on their own workspace -------------------------------------------

-- Each opens on its workspace, and that workspace comes to the front.
for _, app in ipairs(nix.apps) do
  hl.window_rule({ match = { class = app.class }, workspace = app.workspace })
end

-- ---- The i3 layout: the hy3 plugin ------------------------------------------

-- hl.plugin.load only names the plugin. Hyprland loads it once this file has
-- run, and then runs the configuration again: from that pass on, hy3 is here.
local hy3
if nix.i3 then
  hl.plugin.load(nix.hy3)
  hy3 = hl.plugin.hy3
end

-- Whether the workspace you are on uses the i3 layout.
local function on_i3()
  if not hy3 then
    return false
  end
  local workspace = hl.get_active_workspace()
  return workspace ~= nil and workspace.tiled_layout == "hy3"
end

-- One key for both kinds of workspace: `normal` on a workspace in Hyprland's
-- layout, `i3` on one in the i3 layout. Either can be nil (or false): then
-- the key does nothing there.
local function either(normal, i3)
  return function()
    local action
    if on_i3() then
      action = i3
    else
      action = normal
    end
    if action then
      hl.dispatch(action)
    end
  end
end

-- What a key does, for the keys list (SUPER + /).
local function describe(normal, i3)
  if nix.groups and hy3 then
    return normal .. " (i3 layout: " .. i3 .. ")"
  elseif hy3 then
    return i3
  end
  return normal
end

-- ---- Groups and tabs --------------------------------------------------------

-- Hyprland's window groups, and on an i3 workspace the same keys for its tabs.
if nix.groups or hy3 then
  local groups = nix.groups

  bind(
    "SUPER + G",
    either(groups and hl.dsp.group.toggle(), hy3 and hy3.change_group("toggletab")),
    describe("Group Windows / Ungroup", "Tabs / Split")
  )
  if groups then
    bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }), "Take Window out of Group")
  end
  for _, way in ipairs({
    { "LEFT", "l", "Left" },
    { "RIGHT", "r", "Right" },
    { "UP", "u", "Up" },
    { "DOWN", "d", "Down" },
    { "H", "l", "Left" },
    { "L", "r", "Right" },
    { "K", "u", "Up" },
    { "J", "d", "Down" },
  }) do
    bind(
      "SUPER + ALT + " .. way[1],
      either(groups and hl.dsp.window.move({ into_group = way[2] }), hy3 and hy3.move_window(way[2])),
      describe("Move Window into Group " .. way[3], "Move Window " .. way[3])
    )
  end

  local next_one = either(groups and hl.dsp.group.next(), hy3 and hy3.focus_tab({ direction = "r", wrap = true }))
  local previous = either(groups and hl.dsp.group.prev(), hy3 and hy3.focus_tab({ direction = "l", wrap = true }))
  bind("SUPER + ALT + TAB", next_one, describe("Next Window in Group", "Next Tab"))
  bind("SUPER + ALT + SHIFT + TAB", previous, describe("Previous Window in Group", "Previous Tab"))
  bind("SUPER + ALT + mouse_down", next_one, describe("Next Window in Group", "Next Tab"))
  bind("SUPER + ALT + mouse_up", previous, describe("Previous Window in Group", "Previous Tab"))
  for index = 1, 9 do
    bind(
      "SUPER + ALT + " .. index,
      either(groups and hl.dsp.group.active({ index = index }), hy3 and hy3.focus_tab({ index = index })),
      describe("Window " .. index .. " in Group", "Tab " .. index)
    )
  end
end

if nix.groups then
  hl.config({
    -- SUPER + H and L go through a group's windows before leaving it, like
    -- the tabs of i3.
    binds = { movefocus_cycles_groupfirst = true },
    -- The tabs look like the bar: its font, and rounded pills. The colours
    -- come with the theme (patch 0009).
    group = {
      groupbar = {
        font_family = "JetBrainsMono Nerd Font",
        font_size = 11,
        font_weight_active = "bold",
        height = 20,
        gaps_in = 4,
        gaps_out = 4,
        gradients = true,
        gradient_rounding = 5,
        gradient_round_only_edges = false,
        indicator_height = 0,
      },
    },
  })
end

-- ---- The i3 layout ----------------------------------------------------------

if hy3 then
  hl.config({
    plugin = {
      hy3 = {
        -- One window gets no tab bar. A second one makes tabs (see below).
        tab_first_window = false,
        -- The tabs look like the bar. The colours come with the theme.
        tabs = {
          height = 22,
          padding = 4,
          radius = 5,
          border_width = 1,
          text_font = "JetBrainsMono Nerd Font",
          text_height = 9,
          render_text = true,
          text_center = true,
        },
      },
    },
  })

  -- Which workspaces use the i3 layout: the ones from your NixOS
  -- configuration, changed by what the key switched in this session. Kept in
  -- a file, because Hyprland runs this configuration again whenever it
  -- reloads.
  local i3 = {}
  for _, id in ipairs(nix.i3_workspaces) do
    i3[id] = true
  end
  local runtime = os.getenv("XDG_RUNTIME_DIR")
  local state = runtime and (runtime .. "/hyprsimple-nix-i3-workspaces")
  local file = state and io.open(state, "r")
  if file then
    for line in file:lines() do
      local id, layout = line:match("^(%d+) (%w+)$")
      if id then
        i3[tonumber(id)] = layout == "i3"
      end
    end
    file:close()
  end

  local function save()
    local out = state and io.open(state, "w")
    if not out then
      return
    end
    for id, on in pairs(i3) do
      out:write(id, " ", on and "i3" or "hyprland", "\n")
    end
    out:close()
  end

  -- A lone tiled window on an i3 workspace fills the screen: no gaps, no
  -- border, no rounded corners. Counted with the tabs that are hidden
  -- (w[t1], not w[tv1]), so two windows in tabs keep the gaps and border.
  -- One rule of each kind per workspace, which the key turns on and off.
  local alone_windows = {}
  local function alone(id)
    return string.format("r[%d-%d] w[t1]", id, id)
  end

  -- Puts a workspace in the layout `i3` says, right away.
  local function apply(id)
    local on = i3[id] == true
    if on then
      hl.workspace_rule({ workspace = tostring(id), layout = "hy3" })
      hl.workspace_rule({ workspace = alone(id), gaps_in = 0, gaps_out = 0 })
    else
      -- Back to the layout and gaps every other workspace has. A rule only
      -- ever adds to the one before, so these are set back, not removed.
      hl.workspace_rule({ workspace = tostring(id), layout = hl.get_config("general.layout") })
      hl.workspace_rule({
        workspace = alone(id),
        gaps_in = hl.get_config("general.gaps_in"),
        gaps_out = hl.get_config("general.gaps_out"),
      })
    end
    if on and not alone_windows[id] then
      alone_windows[id] = hl.window_rule({
        name = "hyprsimple-nix-i3-alone-" .. id,
        match = { float = false, workspace = alone(id) },
        border_size = 0,
        rounding = 0,
      })
    end
    if alone_windows[id] then
      alone_windows[id]:set_enabled(on)
    end
  end

  -- At the start, only the workspaces in the i3 layout need rules.
  for id, on in pairs(i3) do
    if on then
      apply(id)
    end
  end

  local function tiled(id, except)
    local count = 0
    for _, window in ipairs(hl.get_windows()) do
      if window.workspace and window.workspace.id == id and not window.floating and window.address ~= except then
        count = count + 1
      end
    end
    return count
  end

  -- Tabs by default, as in i3: the second window turns the workspace into
  -- tabs, and when one window is left, the tab bar goes away. In between, a
  -- layout you made yourself stays. hy3 changes the workspace you are on.
  local function here(id)
    local active = hl.get_active_workspace()
    return i3[id] and active ~= nil and active.id == id
  end
  hl.on("window.open", function(window)
    if window and not window.floating and window.workspace and here(window.workspace.id) then
      if tiled(window.workspace.id) == 2 then
        hl.dispatch(hy3.change_group("tab"))
      end
    end
  end)
  hl.on("window.close", function(window)
    if window and window.workspace and here(window.workspace.id) then
      if tiled(window.workspace.id, window.address) <= 1 then
        hl.dispatch(hy3.change_group("h"))
      end
    end
  end)

  bind("SUPER + CTRL + SPACE", function()
    local workspace = hl.get_active_workspace()
    if not workspace or workspace.special then
      return
    end
    i3[workspace.id] = not i3[workspace.id]
    apply(workspace.id)
    save()
    if i3[workspace.id] and tiled(workspace.id) == 2 then
      hl.dispatch(hy3.change_group("tab"))
    end
  end, "Switch This Workspace: Hyprland / i3 Layout")

  -- Splits, as in i3.
  bind("SUPER + CTRL + H", either(nil, hy3.make_group("h")), "i3 Layout: Next Window Beside")
  bind("SUPER + CTRL + J", either(nil, hy3.make_group("v")), "i3 Layout: Next Window Below")
  bind("SUPER + CTRL + E", either(nil, hy3.change_group("opposite")), "i3 Layout: Turn the Split")

  -- Moving the focus goes through tabs and splits on an i3 workspace.
  for _, way in ipairs({ { "H", "l", "Left" }, { "J", "d", "Down" }, { "K", "u", "Up" }, { "L", "r", "Right" } }) do
    hl.unbind("SUPER + " .. way[1])
    bind(
      "SUPER + " .. way[1],
      either(hl.dsp.focus({ direction = way[2] }), hy3.move_focus(way[2])),
      "Focus " .. way[3]
    )
  end
end

-- ---- Keys for workspaces 11 and 12 ------------------------------------------

-- Keys are named by their place on the keyboard (code:), so they stay where
-- they are in every keyboard layout. 20 and 21 are the two keys after 0,
-- - and = on a US keyboard.
if nix.workspaces_11_12 then
  for _, key in ipairs({ { 20, "11" }, { 21, "12" } }) do
    local code, workspace = "code:" .. key[1], key[2]
    bind("SUPER + " .. code, hl.dsp.focus({ workspace = workspace }), "Workspace " .. workspace)
    bind("SUPER + SHIFT + " .. code, hl.dsp.window.move({ workspace = workspace }), "Move to Workspace " .. workspace)
  end
end

-- ---- The number pad ---------------------------------------------------------

if nix.numpad then
  -- The number pad's keys, by their place: they are the same keys with
  -- Num Lock on and off.
  local pad = { [0] = 90, 87, 88, 89, 83, 84, 85, 79, 80, 81 }
  local function key(number)
    return "code:" .. pad[number]
  end

  -- The first or the last workspace there is now.
  local function edge(last)
    return function()
      local found
      for _, workspace in ipairs(hl.get_workspaces()) do
        local id = workspace.id
        if not workspace.special and id > 0 and (found == nil or (last and id > found) or (not last and id < found)) then
          found = id
        end
      end
      if found then
        hl.dispatch(hl.dsp.focus({ workspace = tostring(found) }))
      end
    end
  end

  bind(key(4), hl.dsp.focus({ workspace = "e-1" }), "Workspace Before")
  bind(key(6), hl.dsp.focus({ workspace = "e+1" }), "Workspace After")
  bind(key(8), edge(false), "First Workspace")
  bind(key(2), edge(true), "Last Workspace")
  bind(key(5), hl.dsp.focus({ workspace = "previous" }), "Back to the Workspace Before")
  bind(key(0), hl.dsp.focus({ workspace = "previous" }), "Back to the Workspace Before")
  bind(key(1), either(hl.dsp.focus({ direction = "l" }), hy3 and hy3.move_focus("l")), "Focus Left")
  bind(key(3), either(hl.dsp.focus({ direction = "r" }), hy3 and hy3.move_focus("r")), "Focus Right")
  bind(key(7), either(hl.dsp.window.move({ direction = "l" }), hy3 and hy3.move_window("l")), "Move Window Left")
  bind(key(9), either(hl.dsp.window.move({ direction = "r" }), hy3 and hy3.move_window("r")), "Move Window Right")
  for number = 0, 9 do
    local workspace = tostring(number == 0 and 10 or number)
    bind("SHIFT + " .. key(number), hl.dsp.focus({ workspace = workspace }), "Workspace " .. workspace)
  end
end
