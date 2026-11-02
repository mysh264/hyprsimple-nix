# Keys, mouse buttons and the touchpad

This page shows you how to change what your keys, your mouse buttons and your
touchpad do. Everything here goes in files in your home folder:

| To change | Edit this file |
|---|---|
| Keys and mouse buttons | `~/.config/hypr/bindings/applications.lua` |
| Touchpad and mouse settings, and touchpad swipes | `~/.config/hypr/input.lua` |
| How the drop-down terminal slides in | `~/.config/hypr/looknfeel.lua` |

You do not rebuild NixOS for these. A few keys are also ready-made NixOS
settings: [keys for workspaces 11 and 12](settings.md#keys-for-workspaces-11-and-12)
and [the number pad](settings.md#the-number-pad).

To see every key you have now, press **SUPER + /**. Every key, button and
swipe a new hyprsimple has is in [Every shortcut](shortcuts.md).

**On this page:**
[How to change the files](#how-to-change-the-files) ·
[Keys](#keys) ·
[Mouse buttons](#mouse-buttons) ·
[The touchpad](#the-touchpad) ·
[The number pad, by hand](#the-number-pad-by-hand) ·
[A drop-down terminal](#a-drop-down-terminal) ·
[A whole layout of your own: an example](#a-whole-layout-of-your-own-an-example)

---

## How to change the files

Every time, it is the same steps:

1. Open a terminal: **SUPER + T**.
2. Open the file, for example:
   ```sh
   nano ~/.config/hypr/bindings/applications.lua
   ```
3. Go to the end of the file (**Ctrl + End**), and add your lines there.
4. Save (**Ctrl + O**, then **Enter**) and close (**Ctrl + X**).
5. Load your change:
   ```sh
   hyprctl reload
   ```
6. Check for mistakes:
   ```sh
   hyprctl configerrors
   ```
   If it prints nothing, or `no errors`, all is well. If a line is wrong,
   it tells you which one. Fix the line, save, and do step 5 again.

> 💡 Lines that start with `--` are notes. Hyprland skips them. That is how
> you switch a line off without deleting it: put `--` in front of it.

---

## Keys

### A key line, piece by piece

```lua
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"), { description = "Notes" })
```

| Piece | What it means |
|---|---|
| `"SUPER + O"` | The keys you press together: first the keys you hold (`SUPER`, `SHIFT`, `CTRL`, `ALT`), then one more key. |
| `hl.dsp.exec_cmd("obsidian")` | What happens. Here: start the program `obsidian`. |
| `{ description = "Notes" }` | The name it gets in the list of keys (**SUPER + /**). |

### What a key can do

Put one of these in the middle of a key line:

| To | Write |
|---|---|
| Start a program | `hl.dsp.exec_cmd("firefox")` |
| Go to workspace 3 | `hl.dsp.focus({ workspace = "3" })` |
| Go to the next workspace | `hl.dsp.focus({ workspace = "e+1" })` |
| Go to the workspace before | `hl.dsp.focus({ workspace = "e-1" })` |
| Go back to the workspace you were on | `hl.dsp.focus({ workspace = "previous" })` |
| Move the window to workspace 3 | `hl.dsp.window.move({ workspace = "3" })` |
| Focus the window on the left | `hl.dsp.focus({ direction = "l" })` (`r` right, `u` up, `d` down) |
| Move the window to the left | `hl.dsp.window.move({ direction = "l" })` |
| Close the window | `hl.dsp.window.close()` |
| Float the window, or tile it again | `hl.dsp.window.float({ action = "toggle" })` |
| Make the window fullscreen, or not | `hl.dsp.window.fullscreen()` |
| Show or hide the scratchpad | `hl.dsp.workspace.toggle_special("magic")` |

### What is a key's name?

Letters and numbers are just themselves: `"SUPER + O"`, `"SUPER + 5"`. Some
other keys:

| Key | Name |
|---|---|
| Enter | `Return` |
| Space bar | `space` |
| Tab, Esc, Backspace, Delete | `Tab`, `Escape`, `BackSpace`, `Delete` |
| Arrows | `Left`, `Right`, `Up`, `Down` |
| F1 to F12 | `F1` … `F12` |
| `-` and `=` | `minus`, `equal` |
| Print Screen | `Print` |

To find the name of **any** key:

1. In a terminal, type:
   ```sh
   nix-shell -p wev --run wev
   ```
   A small window opens.
2. Move the mouse into that window, and press your key.
3. Look in the terminal for the line with `sym:`. The word after it is the
   key's name. For the minus key: `sym: minus`.
4. Close the small window.

A key can also be named by its **place** on the keyboard: `code:` and a
number, like `"SUPER + code:20"`. Then it stays the same key in every
keyboard layout (English, Arabic, French …). The number is wev's `key:`
number **plus 8**: wev shows `key: 12` for the minus key, so its name is
`code:20`.

### Change a key that already does something

Take the old meaning away first, with `hl.unbind`, then give the key its new
one:

```lua
hl.unbind("SUPER + B")
hl.bind("SUPER + B", hl.dsp.exec_cmd("brave"), { description = "Browser" })
```

`hl.unbind` needs the keys written the way they were bound, with the held
keys in the same order: `"SUPER + CTRL + LEFT"` takes away SUPER + CTRL + ←,
`"CTRL + SUPER + LEFT"` takes away nothing. Big or small letters do not
matter. [Every shortcut](shortcuts.md) shows each key the way to write it.

### Keys that come from your NixOS settings

The keys of [window groups](settings.md#window-groups-tabs),
[the i3 layout](settings.md#the-i3-layout-tabs-and-splits-like-i3) and
[the number pad](settings.md#the-number-pad) do jobs that have names. To
give a job another key, use its name:

```lua
hl.bind("SUPER + Y", hyprsimple_nix.jobs.switch_layout, { description = "Switch This Workspace: Hyprland / i3 Layout" })
```

Now **SUPER + Y** does what **SUPER + CTRL + SPACE** does. To take it away
from SUPER + CTRL + SPACE, add `hl.unbind("SUPER + CTRL + SPACE")` above
that line.

| Name | What it does | Its key now |
|---|---|---|
| `switch_layout` | Switches the workspace you are on between Hyprland's layout and i3's | SUPER + CTRL + SPACE |
| `next_beside` | i3 layout: the next window you open goes beside this one | SUPER + CTRL + H |
| `next_below` | i3 layout: the next window you open goes below this one | SUPER + CTRL + J |
| `turn_split` | i3 layout: side by side becomes on top of each other, and back | SUPER + CTRL + E |
| `focus_left`, `focus_right`, `focus_up`, `focus_down` | Focus the window that way, through the tabs and splits of the i3 layout too | SUPER + H, L, K, J |
| `group` | Makes the windows a group (tabs), or undoes it. i3 layout: tabs, or side by side | SUPER + G |
| `leave_group` | Takes the window out of its group | SUPER + ALT + G |
| `into_group_left`, `into_group_right`, `into_group_up`, `into_group_down` | Moves the window into the group that way. i3 layout: moves the window that way | SUPER + ALT + arrows |
| `next_tab`, `previous_tab` | The next or the previous window in the group, or tab | SUPER + ALT + TAB, SUPER + ALT + SHIFT + TAB |
| `tab_1` … `tab_9` | Window 1 … 9 of the group, or tab | SUPER + ALT + 1 … 9 |
| `move_left`, `move_right`, `move_up`, `move_down` | Moves the window that way, in both layouts | 7 and 9 on the number pad |
| `first_workspace`, `last_workspace` | The first or the last workspace with windows | 8 and 2 on the number pad |

Every name is there, whatever your settings: one whose setting is off does
nothing, so your keys never stop the file from loading.

---

## Mouse buttons

### Every button's name

| Button | Name |
|---|---|
| Left button | `mouse:272` |
| Right button | `mouse:273` |
| Middle button (press the wheel down) | `mouse:274` |
| Side button, back (on most mice the one nearer you) | `mouse:275` |
| Side button, forward | `mouse:276` |
| More buttons, on mice that have them | `mouse:277`, `mouse:278`, … |
| Wheel turned up | `mouse_up` |
| Wheel turned down | `mouse_down` |
| Wheel pushed to the left (tilt) | `mouse_left` |
| Wheel pushed to the right (tilt) | `mouse_right` |

Mice are not all the same. To find a button's number, use wev (see
[What is a key's name?](#what-is-a-keys-name)): click the button inside its
window, and look for `button: 275` in the terminal.

### What the mouse does now

| You do | It does |
|---|---|
| Hold **SUPER**, hold the **left** button, move | Moves a window |
| Hold **SUPER**, hold the **right** button, move | Changes a window's size |
| Hold **SUPER**, turn the **wheel** | Next or previous workspace |

### Give a button a job

Mouse buttons go in key lines, like keys. Some examples to copy:

**The side buttons switch workspaces** (while you hold SUPER):

```lua
hl.bind("SUPER + mouse:275", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace Before" })
hl.bind("SUPER + mouse:276", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace After" })
```

Without `SUPER + ` (just `"mouse:275"`), the button does this everywhere,
with no key held, and does nothing else any more: your browser's back button
stops working.

**SUPER + middle click closes the window:**

```lua
hl.bind("SUPER + mouse:274", hl.dsp.window.close(), { description = "Close Window" })
```

**An extra button (on a mouse that has more) goes back to the workspace you
were on:**

```lua
hl.bind("mouse:277", hl.dsp.focus({ workspace = "previous" }), { description = "Back to the Workspace Before" })
```

**SUPER + wheel goes the other way:**

```lua
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace Before" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace After" })
```

**Move windows while holding ALT, instead of SUPER:**

```lua
hl.unbind("SUPER + mouse:272")
hl.bind("ALT + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move Window" })
```

> ⚠️ `mouse = true` is only for holding a button and moving (moving or
> resizing a window, as above). Leave it out of a button you just click.

### Mouse settings

These go in `~/.config/hypr/input.lua`. Keep only the lines you want to
change:

```lua
hl.config({
  input = {
    -- The pointer: slower (down to -1.0) or faster (up to 1.0). 0 is normal.
    sensitivity = -0.3,
    -- "flat": no speed-up, the pointer moves as far as your hand does.
    accel_profile = "flat",
    -- true: the wheel scrolls the other way.
    natural_scroll = false,
    -- true: the left and right buttons swap places.
    left_handed = false,
    -- The wheel scrolls further (2.0) or less far (0.5).
    scroll_factor = 1.0,
  },
})
```

---

## The touchpad

### Touchpad settings

These go in `~/.config/hypr/input.lua`. hyprsimple already turns on
`natural_scroll`: the page moves with your fingers, like on a phone. Keep
only the lines you want to change:

```lua
hl.config({
  input = {
    touchpad = {
      -- false: two fingers scroll the other way.
      natural_scroll = true,
      -- A tap is a click.
      tap_to_click = true,
      -- Tap with 2 fingers: right click. Tap with 3: middle click.
      -- ("lmr" is the other way round: 2 fingers middle, 3 fingers right.)
      tap_button_map = "lrm",
      -- Press the touchpad down with 2 fingers: right click. With 3: middle.
      clickfinger_behavior = true,
      -- The touchpad does nothing while you type.
      disable_while_typing = true,
      -- Tap, then tap again and keep the finger down, to drag.
      tap_and_drag = true,
      -- Two fingers scroll further (2.0) or less far (0.5).
      scroll_factor = 1.0,
    },
  },
})
```

### Touchpad swipes

A swipe is a line like this one:

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
```

It means: **3** fingers, moving **left or right**, change the
**workspace**. hyprsimple has this line, switched off. To have it, put it in
`~/.config/hypr/input.lua`, then `hyprctl reload`.

The three pieces:

| Piece | You can write |
|---|---|
| `fingers` | `3` or `4`. (Two fingers are for scrolling.) |
| `direction` | `"left"`, `"right"`, `"up"`, `"down"`, `"horizontal"` (left or right), `"vertical"` (up or down), `"swipe"` (any way), `"pinch"`, `"pinchin"`, `"pinchout"` (fingers together or apart) |
| `action` | one of the jobs below |

| `action` | What it does |
|---|---|
| `"workspace"` | Changes the workspace, and the screen follows your fingers. Use it with `"horizontal"` or `"vertical"`. |
| `"move"` | Moves the window under your fingers |
| `"resize"` | Changes the window's size |
| `"close"` | Closes the window |
| `"fullscreen"` | Makes the window fullscreen, or not |
| `"float"` | Floats the window, or tiles it again |
| `"special"` | Shows or hides the scratchpad. Add `workspace_name = "magic"`, the name of hyprsimple's scratchpad. |
| a `function` | Anything a key can do (see the last example). It runs once, when your fingers lift. |

More swipes to copy:

```lua
-- 4 fingers up: fullscreen, and up again: back.
hl.gesture({ fingers = 4, direction = "up", action = "fullscreen" })

-- 4 fingers down: show or hide the scratchpad.
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "magic" })

-- 3 fingers up: back to the workspace you were on.
hl.gesture({
  fingers = 3,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.focus({ workspace = "previous" }))
  end,
})
```

> 💡 Put each swipe in only once. And two swipes with the same fingers must
> go different ways: 3 fingers `"horizontal"` and 3 fingers `"up"` work
> together; 3 fingers `"horizontal"` and 3 fingers `"left"` do not.
> `hyprctl configerrors` tells you when two swipes are in each other's way.

---

## The number pad, by hand

The ready-made setting is [here](settings.md#the-number-pad). To give the
number pad other jobs, name its keys by their place (`code:`), which works
with Num Lock on and off:

| Number pad key | Name |
|---|---|
| 0 | `code:90` |
| 1 | `code:87` |
| 2 | `code:88` |
| 3 | `code:89` |
| 4 | `code:83` |
| 5 | `code:84` |
| 6 | `code:85` |
| 7 | `code:79` |
| 8 | `code:80` |
| 9 | `code:81` |
| `.` | `code:91` |
| `+` | `code:86` |
| `-` | `code:82` |
| `*` | `code:63` |
| `/` | `code:106` |
| Enter | `code:104` |

For example, **SUPER + a number on the number pad** goes to that workspace,
and the number pad still types numbers without SUPER:

```lua
local pad = { [0] = 90, 87, 88, 89, 83, 84, 85, 79, 80, 81 }
for number = 1, 9 do
  hl.bind("SUPER + code:" .. pad[number], hl.dsp.focus({ workspace = tostring(number) }), { description = "Workspace " .. number })
end
hl.bind("SUPER + code:90", hl.dsp.focus({ workspace = "10" }), { description = "Workspace 10" })
```

A key with no held key in front (just `"code:85"`) does its job everywhere,
and no longer types its number.

---

## A drop-down terminal

Ghostty, the terminal hyprsimple uses, has a drop-down terminal of its own.
One key slides it down from the top of the screen, over your windows, and
the same key slides it away again. What you typed in it stays there.

Give it a key, in `~/.config/hypr/bindings/applications.lua`:

```lua
hl.bind("F12", hl.dsp.exec_cmd("sh -c 'systemctl --user start app-com.mitchellh.ghostty.service && ghostty +toggle-quick-terminal'"), { description = "Drop-down Terminal" })
```

The first part starts Ghostty in the background, the first time you press the
key. Without it, that very first press opens an ordinary Ghostty window
instead.

To have it slide down, with what is behind it blurred, add this to
`~/.config/hypr/looknfeel.lua`:

```lua
hl.layer_rule({ match = { namespace = "ghostty-quick-terminal" }, blur = true, ignore_alpha = 0.1, animation = "slide top" })
```

Its size, and whether it slides away by itself when you click somewhere
else, are Ghostty settings. They go in `~/.config/ghostty/config`:

```
quick-terminal-size = 50%
quick-terminal-autohide = true
```

---

## A whole layout of your own: an example

This is one i3 user's layout. It moves many keys at once, so it shows every
way of doing it: keys taken away with `hl.unbind`, hyprsimple's jobs on
other keys, jobs [by name](#keys-that-come-from-your-nixos-settings), new
keys, and the mouse's side buttons. Copy what you like.

| Keys | What they do now | Before |
|---|---|---|
| **SUPER + ←, →, ↑, ↓** | Focus the window that way | SUPER + H, L, K, J |
| **SUPER + CTRL + arrows** | Window bigger or smaller | SUPER + SHIFT + arrows |
| **SUPER + SHIFT + arrows** | Move the window into a group (i3 layout: move it) | SUPER + ALT + arrows |
| **SUPER + ALT + arrows** | Move the workspace to another screen | SUPER + CTRL + arrows |
| **SUPER + ENTER** | Terminal (SUPER + T still works too) | nothing |
| **SUPER + D** | App launcher | SUPER + A |
| **SUPER + P** | Colour picker | SUPER + M |
| **SUPER + Z** | Float the window, or tile it again | SUPER + W |
| **SUPER + SHIFT + F** | Fullscreen, and back | nothing |
| **SUPER + TAB**, **SUPER + SHIFT + TAB** | Next or previous workspace, and round again | nothing |
| **SUPER + S** | Show or hide the scratchpad | sound panel |
| **SUPER + SHIFT + S** | The window into the scratchpad, or back out of it | into the scratchpad |
| **SUPER + SHIFT + G** | Take the window out of its group | SUPER + ALT + G |
| **SUPER + A** | Switch the workspace: Hyprland's layout or i3's | SUPER + CTRL + SPACE |
| **SUPER + H**, **SUPER + J**, **SUPER + E** | i3 layout: next window beside, below, turn the split | SUPER + CTRL + H, J, E |
| **SUPER + SHIFT + A** | Sound panel | SUPER + S |
| **SUPER + ALT + D** | Notifications panel | SUPER + SHIFT + D |
| **SUPER + SHIFT + D** | Clear the notifications | SUPER + D |
| **SUPER + SHIFT + E** | Power menu (SUPER + ESC still works too) | nothing |
| **SUPER + L** | Lock the screen | SUPER + SHIFT + L |
| **SUPER + M** | Hide or show the bar (CTRL + ESC still works too) | colour picker |
| **SUPER + PRINT** | Screenshot of the whole screen, at once | nothing |
| **SHIFT + PRINT** | Screenshot of the window you are in, at once | nothing |
| **. on the number pad**, mouse **forward** button | [Drop-down terminal](#a-drop-down-terminal) | nothing |
| mouse **back** button | Back to the workspace you were on | nothing |
| **SUPER + X** | Nothing (the power menu has Log out) | log out |

And **SUPER + a workspace's number**, or a click on its name on the bar,
takes you back to the workspace before when you are on it already, like i3's
`workspace_auto_back_and_forth`.

It needs [window groups](settings.md#window-groups-tabs) and
[the i3 layout](settings.md#the-i3-layout-tabs-and-splits-like-i3) on, and
the [drop-down terminal](#a-drop-down-terminal)'s slide comes from its
`looknfeel.lua` line. Put the whole block at the end of
`~/.config/hypr/bindings/applications.lua`, then `hyprctl reload`:

```lua
-- An i3 user's keys. The keys this block gives a new job are taken away from
-- their old one first, so no key does two things.
local vars = require("default.hypr.vars")
local jobs = hyprsimple_nix.jobs
local home = os.getenv("HOME")
local shots = home .. "/Pictures/Screenshots"

for _, keys in ipairs({
  "SUPER + A", "SUPER + M", "SUPER + W", "SUPER + D", "SUPER + S", "SUPER + X",
  "SUPER + H", "SUPER + J", "SUPER + K", "SUPER + L",
  "SUPER + SHIFT + RIGHT", "SUPER + SHIFT + LEFT", "SUPER + SHIFT + UP", "SUPER + SHIFT + DOWN",
  "SUPER + CTRL + LEFT", "SUPER + CTRL + RIGHT", "SUPER + CTRL + UP", "SUPER + CTRL + DOWN",
  "SUPER + SHIFT + S", "SUPER + SHIFT + L", "SUPER + SHIFT + D",
  "SUPER + ALT + G", "SUPER + ALT + LEFT", "SUPER + ALT + RIGHT", "SUPER + ALT + UP", "SUPER + ALT + DOWN",
  "SUPER + ALT + H", "SUPER + ALT + L", "SUPER + ALT + K", "SUPER + ALT + J",
  "SUPER + ALT + TAB", "SUPER + ALT + SHIFT + TAB",
  "SUPER + CTRL + SPACE", "SUPER + CTRL + H", "SUPER + CTRL + J", "SUPER + CTRL + E",
}) do
  hl.unbind(keys)
end

-- Apps.
hl.bind("SUPER + Return", hl.dsp.exec_cmd(vars.terminal), { description = "Terminal" })
hl.bind("SUPER + D", hl.dsp.exec_cmd(vars.menu), { description = "App Launcher" })
hl.bind("SUPER + P", hl.dsp.exec_cmd("sh -c '" .. vars.colorPicker .. " | wl-copy'"), { description = "Color Picker" })

-- Windows.
hl.bind("SUPER + Z", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen(), { description = "Fullscreen" })
hl.bind("SUPER + Left", jobs.focus_left, { description = "Focus Left" })
hl.bind("SUPER + Right", jobs.focus_right, { description = "Focus Right" })
hl.bind("SUPER + Up", jobs.focus_up, { description = "Focus Up" })
hl.bind("SUPER + Down", jobs.focus_down, { description = "Focus Down" })
hl.bind("SUPER + CTRL + Right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { description = "Resize Right", repeating = true })
hl.bind("SUPER + CTRL + Left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { description = "Resize Left", repeating = true })
hl.bind("SUPER + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { description = "Resize Up", repeating = true })
hl.bind("SUPER + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { description = "Resize Down", repeating = true })

-- Workspaces. SUPER + TAB goes round: after the last workspace, the first.
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "e+1" }), { description = "Next Workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous Workspace" })
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), { description = "Show / Hide the Scratchpad" })
hl.bind("SUPER + SHIFT + S", function()
  local window = hl.get_active_window()
  if not window then
    return
  end
  if window.workspace and window.workspace.special then
    local here = hl.get_active_workspace()
    if here then
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(here.id) }))
    end
  else
    hl.dispatch(hl.dsp.window.move({ workspace = "special:magic", follow = false }))
  end
end, { description = "Window into / out of the Scratchpad" })
for _, way in ipairs({ { "Left", "l" }, { "Right", "r" }, { "Up", "u" }, { "Down", "d" } }) do
  hl.bind("SUPER + ALT + " .. way[1], hl.dsp.workspace.move({ monitor = way[2] }), { description = "Move Workspace to " .. way[1] .. " Monitor" })
end
-- SUPER + the workspace you are on, or a click on it on the bar, goes back to
-- the one before, like i3's workspace_auto_back_and_forth.
hl.config({ binds = { workspace_back_and_forth = true } })

-- Window groups and the i3 layout.
hl.bind("SUPER + SHIFT + G", jobs.leave_group, { description = "Take Window out of Group" })
hl.bind("SUPER + SHIFT + Left", jobs.into_group_left, { description = "Move Window into Group Left (i3 layout: Move Window Left)" })
hl.bind("SUPER + SHIFT + Right", jobs.into_group_right, { description = "Move Window into Group Right (i3 layout: Move Window Right)" })
hl.bind("SUPER + SHIFT + Up", jobs.into_group_up, { description = "Move Window into Group Up (i3 layout: Move Window Up)" })
hl.bind("SUPER + SHIFT + Down", jobs.into_group_down, { description = "Move Window into Group Down (i3 layout: Move Window Down)" })
hl.bind("SUPER + A", jobs.switch_layout, { description = "Switch This Workspace: Hyprland / i3 Layout" })
hl.bind("SUPER + H", jobs.next_beside, { description = "i3 Layout: Next Window Beside" })
hl.bind("SUPER + J", jobs.next_below, { description = "i3 Layout: Next Window Below" })
hl.bind("SUPER + E", jobs.turn_split, { description = "i3 Layout: Turn the Split" })

-- Panels on the bar, and the system.
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(vars.barPanel .. "volume"), { description = "Sound (panel: volume and output device)" })
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd(vars.barPanel .. "notifications"), { description = "Notifications (panel)" })
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(home .. "/.local/bin/notification-dismiss.sh"), { description = "Dismiss Notifications" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(vars.powermenu), { description = "Power Menu" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"), { description = "Lock Screen" })
hl.bind("SUPER + M", hl.dsp.exec_cmd(home .. "/.local/bin/hyprsimple-restart-bar.sh --toggle"), { description = "Toggle Bar" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hyprshot -m output -m active --output-folder " .. shots), { description = "Screenshot of the Whole Screen" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m window -m active --output-folder " .. shots), { description = "Screenshot of the Window" })

-- The drop-down terminal (see "A drop-down terminal"), and the side buttons
-- of the mouse: forward for the drop-down terminal, back for the workspace
-- before.
local dropdown = hl.dsp.exec_cmd("sh -c 'systemctl --user start app-com.mitchellh.ghostty.service && ghostty +toggle-quick-terminal'")
hl.bind("code:91", dropdown, { description = "Drop-down Terminal" })
hl.bind("mouse:276", dropdown, { description = "Drop-down Terminal" })
hl.bind("mouse:275", hl.dsp.focus({ workspace = "previous" }), { description = "Back to the Workspace Before" })
```
