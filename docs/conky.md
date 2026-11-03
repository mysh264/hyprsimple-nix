# The Conky panel

A clean little panel on your desktop: the time and the date, the weather, and
how busy your computer is (its processor, memory, graphics card, disks and
network). It sits on the right of the screen, behind your windows, on top of
the wallpaper.

It is [Lean Conky Config](https://github.com/jxai/lean-conky-config) by Jason
Xu, from its Wayland version,
**[lean-conky-config-wayland](https://github.com/mysh264/lean-conky-config-wayland)**:
the original, with what it needs to run on Wayland, a GPU part for every
graphics card (Intel, AMD, NVIDIA), its text in Roboto, and everything a new
computer needs. That repository has the full guide to changing it,
[CUSTOMIZE.md](https://github.com/mysh264/lean-conky-config-wayland/blob/master/CUSTOMIZE.md).

**On this page:**
[Turn it on](#turn-it-on) ·
[Change how it looks](#change-how-it-looks) ·
[Its place](#its-place-on-the-screen) ·
[The background](#the-background-color-see-through-blur) ·
[The GPU part](#the-gpu-part) ·
[Restart it](#restart-it) ·
[A new version](#a-new-version) ·
[Turn it off](#turn-it-off) ·
[When something goes wrong](#when-something-goes-wrong)

---

## Turn it on

1. Add this line to your NixOS configuration (`sudo nano /etc/nixos/configuration.nix`),
   inside the outer `{ }`:

   ```nix
     programs.hyprsimple.conky.enable = true;
   ```

2. Rebuild: `sudo nixos-rebuild switch`.
3. Log out and back in.

The panel appears on the right of your screen, a few seconds after you log
in, and from then on at every login.

On NixOS 26.05, the first rebuild takes a few minutes longer: it builds a
newer Conky (1.25.3) for the panel, because 26.05's own (1.22.3) cannot draw
it on Wayland.

**What happened:** the first time, the panel was copied into a folder of your
own, **`~/.config/lean-conky-config`**, and it runs from there. Its fonts (the
icons, the clock's digits, and Roboto for the text) were put in
`~/.local/share/fonts`. Everything it needs (Conky, Python, curl, lspci...)
came with the setting. Its dark background is exactly as tall as the panel,
and the wallpaper behind it is blurred.

> 💡 The [top right hot corner](corners.md) shows the desktop: a quick way to
> see the panel when windows cover it.

---

## Change how it looks

Your changes go in **one file of your own**,
`~/.config/lean-conky-config/local.conf`. Nothing ever overwrites it.

1. Open a terminal (**SUPER + T**), go to the panel's folder, and make your
   `local.conf` (only the first time):

   ```sh
   cd ~/.config/lean-conky-config
   cp local.conf.example local.conf
   ```

2. Open it:

   ```sh
   nano local.conf
   ```

   Every setting is there, switched off: a line that starts with `--` is a
   note. Delete the `--` to switch a line on, and change its value. (So right
   after copying, the panel is still the same.)

3. Save (**Ctrl + O**, **Enter**), close (**Ctrl + X**), and
   [restart the panel](#restart-it).

Some first changes, each going inside the part it names. The list of parts,
`lcc.panel`, is switched off as a whole: for a change there, first delete the
`--` in front of each of its lines, from `lcc.panel = {` to its `}`.

| To | Write |
|---|---|
| Make it bigger (1 is normal) | In `lcc.config`: `scale = 1.5,` |
| Put it on the left | In `conky.config`: `alignment = "top_left",` |
| Move it away from the edge | In `conky.config`: `gap_x = T_.sr(20), gap_y = T_.sr(40),` |
| Make the clock orange | In `conky.config`: `color0 = "orange",` |
| A blue background | In `conky.config`: `own_window_colour = "#1a3a5a",` |
| A see-through background | In `conky.config`: `own_window_argb_value = 0,` |
| The weather of your city | In `lcc.panel`: `{ "weather", { location = "Dubai" } },` |
| List the programs that use the GPU | In `lcc.panel`: `{ "gpu", { top_n = 3 } },` |
| No GPU part | In `lcc.panel`: take out the `"gpu"` line |
| All the text in another font | In `lcc.config`: `font_family = "Ubuntu",` |

[CUSTOMIZE.md](https://github.com/mysh264/lean-conky-config-wayland/blob/master/CUSTOMIZE.md)
explains every one of them, and more: colors, fonts, which parts it shows,
the GPU part, disks, and parts of your own.

### Its place on the screen

In `conky.config`, in your `local.conf`:

```lua
conky.config = {
    alignment = "bottom_left",
    gap_x = T_.sr(20),
    gap_y = T_.sr(10),
}
```

- **`alignment`** is the corner or edge it sits against: `"top_left"`,
  `"top_middle"`, `"top_right"` (the normal one), `"middle_left"`,
  `"middle_right"`, `"bottom_left"`, `"bottom_middle"` or `"bottom_right"`.
- **`gap_x`** is its distance from the left or right edge of the screen, and
  **`gap_y`** from the top or bottom edge, in pixels. (`T_.sr(...)` makes them
  grow with the panel's `scale`.)

It keeps clear of the bar: at the bottom of the screen, it sits just above a
bar there, and `gap_y` counts from the bar's edge. The example puts it in the
bottom left corner, 20 pixels from the side and 10 above the bar.

### The background: color, see-through, blur

In `conky.config`, in your `local.conf`:

```lua
conky.config = {
    own_window_colour = "#1a3a5a",
    own_window_argb_value = 200,
}
```

- **`own_window_colour`** is its color: a name, like `"black"` (the normal
  one) or `"navy"`, or a code, like `"#1a3a5a"` (the one a color picker
  shows). Conky then says it calls this `own_window_color` now: harmless,
  the old name works with every Conky.
- **`own_window_argb_value`** is how solid it is: `0` is fully see-through,
  `255` fully solid, and the normal one is `128`, half.

It is always as tall as the panel: add a part, or take one away, and the
background grows or shrinks with it.

**The blur** behind it comes from Hyprland, and is on. In your NixOS
configuration:

- To turn it off:

  ```nix
    programs.hyprsimple.conky.blur = false;
  ```

- To make it stronger or softer, set Hyprland's blur, which is the same for
  everything it blurs (the panel, the drop-down terminal, see-through windows):

  ```nix
    programs.hyprsimple.extraConfig = ''
      hl.config({ decoration = { blur = { size = 8, passes = 3 } } })
    '';
  ```

  `size` is how far the blur spreads (hyprsimple's is 5): bigger is
  blurrier. `passes` is how many times it blurs (hyprsimple's is 3): more is
  smoother. A blur set in `~/.config/hypr/looknfeel.lua` wins over this one.

Then rebuild, type `hyprctl reload`, and [restart the panel](#restart-it).
The blur only shows through a background that is not fully solid: with
`own_window_argb_value = 255`, there is nothing to see through.

### The GPU part

Under the memory, the panel shows each graphics card (GPU) of the computer:
how busy it is, its name, and its temperature, with a graph of each. An Intel
GPU, like most laptops have, has no temperature of its own (it is part of the
processor), so it shows its clock instead. AMD and NVIDIA cards also show
their clock, power and memory. It needs nothing extra: Intel and AMD tell
Linux all of it, and NVIDIA's driver comes with `nvidia-smi`.

- **The programs that use it most:** `{ "gpu", { top_n = 3 } },` in
  `lcc.panel`. Each line makes the panel about 13 pixels taller.
- **A laptop with two GPUs** shows both. The second one sleeps while no
  program needs it; the panel leaves it asleep, and says `asleep`.
- **No GPU part:** take the `"gpu"` line out of `lcc.panel`. A computer without
  a real GPU (a virtual machine) has none anyway.

[The GPU part](https://github.com/mysh264/lean-conky-config-wayland/blob/master/CUSTOMIZE.md#the-gpu-part)
in CUSTOMIZE.md has the rest: choosing one GPU, and NVIDIA's own way.

---

## Restart it

After a change, type in a terminal:

```sh
lean-conky-config
```

It stops the panel that runs, and starts it again, with your change.

---

## A new version

A new version of the panel comes with a new hyprsimple-nix, and goes into
your copy in `~/.config/lean-conky-config` by itself, at your next login after
the rebuild. Your `local.conf` stays as it is.

Only if you changed one of the panel's own files (not `local.conf`), your copy
stays as it was, and the panel says which files, in
`journalctl --user -b | grep -A3 "Lean Conky"`. To take the new version all
the same, start again from a fresh copy with these four lines:

```sh
mv ~/.config/lean-conky-config ~/.config/lean-conky-config.old
lean-conky-config
cp ~/.config/lean-conky-config.old/local.conf ~/.config/lean-conky-config/
lean-conky-config
```

The first line moves your old copy aside. The second makes a new copy and
starts it. The third brings your `local.conf` back, and the fourth restarts
the panel with it. (No `local.conf` yet? Skip the last two lines.)

A copy made by an older hyprsimple-nix needs these four lines once, too: it
does not have the list of its files that new versions go by. See if yours
has it: `ls ~/.config/lean-conky-config/.lean-conky-config.sha256`.

---

## Turn it off

Take the line out of your configuration (or write `false` instead of `true`),
rebuild, and log out and back in. Your folder `~/.config/lean-conky-config`
stays, with your changes; delete it if you do not want it any more.

To hide the panel only for now, stop it: `pkill -x conky`.

---

## When something goes wrong

**The panel does not appear.** Start it by hand, and read what it says (stop it
with **Ctrl + C**):

```sh
cd ~/.config/lean-conky-config
conky -c conky.conf
```

A line naming `local.conf` and a number points at a mistake there: fix that
line, or rename `local.conf` to try without it.

**The dark background reaches below the panel.** Your copy is from an older
hyprsimple-nix: `ls ~/.config/lean-conky-config/.lean-conky-config.sha256`
says there is no such file. Take the [new version](#a-new-version) with the
four lines. It fixes the two causes: Conky measured the panel taller than it
draws it (the Conky that comes with it now measures it right), and the
network part left empty lines at its end.

**Little squares instead of icons, or the text in another font.** The font
links are missing; restarting the panel puts them back: `lean-conky-config`.

**The weather's humidity touches its temperature, or there is no GPU part.**
Your copy did not take the new version: see if
`ls ~/.config/lean-conky-config/font/Roboto-Regular.ttf` finds the file. If
not, rebuild with `--option tarball-ttl 0` to get the new hyprsimple-nix, then
restart the panel: `lean-conky-config`. Still not there? Your copy has changes
of your own: take the [new version](#a-new-version) with the four lines.

**Messages like `'out_to_wayland' is deprecated`.** Harmless: Conky is newer
than some settings the panel writes the old way. (`Fontconfig error: the
ambiguous constant name: normal` comes from a font with `:normal` in your
`local.conf`: write `Roboto:size=8`, not `Roboto:normal:size=8`.)

**No weather.** It needs the internet. If it shows the wrong place, write your
city, as in the table above.

> 💡 The panel's own `tools/check-lcc` looks for programs where other Linux
> systems keep them, so on NixOS it reports some as missing that the panel
> has. `lean-conky-config` brings them all.
