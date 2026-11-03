# Hot corners

Push the mouse pointer into a corner of the screen, and something happens:
the bar hides, the desktop shows, you go back to the workspace before. Each
corner has its own job, and you choose it.

A corner works **once** each time you go there. Leave the pointer in the
corner, and nothing more happens. Move it away a little, and the corner
works again. While a window is **full screen** (a film, a game), the corners
rest, so they never get in the way.

**On this page:**
[Turn them on](#turn-them-on) ·
[What a corner can do](#what-a-corner-can-do) ·
[Give a corner another job](#give-a-corner-another-job) ·
[Make a corner easier to hit](#make-a-corner-easier-to-hit) ·
[Anything at all, in Lua](#anything-at-all-in-lua) ·
[Turn them off](#turn-them-off)

---

## Turn them on

1. Add this line to your NixOS configuration (`sudo nano /etc/nixos/configuration.nix`),
   inside the outer `{ }`:

   ```nix
     programs.hyprsimple.corners.enable = true;
   ```

2. Rebuild: `sudo nixos-rebuild switch`.
3. Type `hyprctl reload` in a terminal (or log out and back in).

Now the corners do this:

| Corner | What happens |
|---|---|
| **Top left** | Hides the bar, or shows it again |
| **Top right** | Shows the desktop: an empty workspace. Go there again, and you are back where you were |
| **Bottom right** | Back to the workspace you were on before |
| **Bottom left** | Nothing |

> 💡 The desktop is workspace 97, kept empty. The bar shows it as **97**
> while you are there.

---

## What a corner can do

A corner's job is one of these words:

| Write | What the corner does |
|---|---|
| `"bar"` | Hides the bar, or shows it again |
| `"desktop"` | Shows the desktop; there again, back to where you were |
| `"back"` | Back to the workspace you were on before |
| `"launcher"` | Opens the app launcher |
| `"terminal"` | Opens a terminal |
| `"dropdown-terminal"` | Slides the [drop-down terminal](settings.md#a-drop-down-terminal) down, or away |
| `"scratchpad"` | Shows or hides the scratchpad |
| `"notifications"` | Opens the notifications panel |
| `"lock"` | Locks the screen |
| `"power-menu"` | Opens the power menu |
| `null` | Nothing |

**Or any command,** the way you would type it in a terminal: `"firefox"`,
`"nautilus"`, `"hyprshot -m output"`. Anything that is not one of the words
above is run as a command.

---

## Give a corner another job

Each corner has its own line. Write the job between quotes:

```nix
  programs.hyprsimple.corners = {
    enable = true;
    topLeft = "launcher";
    topRight = "desktop";
    bottomLeft = "firefox";
    bottomRight = null;
  };
```

Here the top left corner opens the app launcher, the bottom left corner
starts Firefox, and the bottom right corner does nothing. A corner you leave
out keeps its job from the table at the top.

Then, as always: rebuild, and `hyprctl reload`.

---

## Make a corner easier to hit

The pointer has to come within 8 pixels of the corner. On a big screen, or
with a fast mouse, give it more room:

```nix
  programs.hyprsimple.corners.size = 20;
```

---

## Anything at all, in Lua

For a job no word or command can do, write it in Lua, Hyprland's own
language, in a file of yours: `~/.config/hypr/bindings/applications.lua`.
Each corner is a little function there:

```lua
-- The bottom left corner: workspace 1, then the app launcher.
hyprsimple_nix.corners.bottom_left = function()
  hl.dispatch(hl.dsp.focus({ workspace = "1" }))
  hl.exec_cmd("qs -p ~/.local/share/hyprsimple/default/quickshell ipc call bar toggle launcher")
end
```

Save, and `hyprctl reload`. The names are `top_left`, `top_right`,
`bottom_left` and `bottom_right`. To take a corner's job away there, write
`hyprsimple_nix.corners.top_left = nil`. The jobs from the table above are
there to use too, by name:

```lua
hyprsimple_nix.corners.bottom_left = hyprsimple_nix.jobs.show_desktop
```

[Keys that come from your NixOS settings](keys.md#keys-that-come-from-your-nixos-settings)
lists every job, and the same jobs can go on keys.

---

## Turn them off

Take the `corners` lines out of your configuration (or write
`enable = false;`), rebuild, and `hyprctl reload`.

---

## How it works

Hyprland has no "corner" event, so hyprsimple-nix looks where the pointer is
20 times a second, in [`modules/hyprland.lua`](../modules/hyprland.lua)
("Hot corners"). Looking is very cheap: it needs no measurable power. It
works on every screen you have, also with scaled or turned screens, and it
uses the corners of the screen the pointer is on.
