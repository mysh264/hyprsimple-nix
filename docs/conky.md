# The Conky panel

A clean little panel on your desktop: the time and the date, the weather, and
how busy your computer is (its processor, memory, disks and network). It sits
on the right of the screen, behind your windows, on top of the wallpaper.

It is [Lean Conky Config](https://github.com/jxai/lean-conky-config) by Jason
Xu, from its Wayland version,
**[lean-conky-config-wayland](https://github.com/mysh264/lean-conky-config-wayland)**:
the original, with only what it needs to run on Wayland, and everything a new
computer needs. That repository has the full guide to changing it,
[CUSTOMIZE.md](https://github.com/mysh264/lean-conky-config-wayland/blob/master/CUSTOMIZE.md).

**On this page:**
[Turn it on](#turn-it-on) ·
[Change how it looks](#change-how-it-looks) ·
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

**What happened:** the first time, the panel was copied into a folder of your
own, **`~/.config/lean-conky-config`**, and it runs from there. Its font (the
icons, the clock's digits) was put in `~/.local/share/fonts`. Everything it
needs (Conky, Python, curl...) came with the setting.

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
   note. Delete the `--` to switch a line on, and change its value.

3. Save (**Ctrl + O**, **Enter**), close (**Ctrl + X**), and
   [restart the panel](#restart-it).

Some first changes, each going inside the part it names:

| To | Write |
|---|---|
| Make it bigger (1 is normal) | In `lcc.config`: `scale = 1.5,` |
| Put it on the left | In `conky.config`: `alignment = "top_left",` |
| Move it away from the edge | In `conky.config`: `gap_x = T_.sr(20), gap_y = T_.sr(40),` |
| Make the clock orange | In `conky.config`: `color0 = "orange",` |
| A see-through background | In `conky.config`: `own_window_argb_value = 0,` |
| The weather of your city | In `lcc.panel`: `{ "weather", { location = "Dubai" } },` |

[CUSTOMIZE.md](https://github.com/mysh264/lean-conky-config-wayland/blob/master/CUSTOMIZE.md)
explains every one of them, and more: colors, fonts, which parts it shows,
disks, an NVIDIA card, and parts of your own.

---

## Restart it

After a change, type in a terminal:

```sh
lean-conky-config
```

It stops the panel that runs, and starts it again, with your change.

---

## A new version

Your copy in `~/.config/lean-conky-config` is yours: new versions of
hyprsimple-nix do not replace it. To start again from the newest version,
type these four lines:

```sh
mv ~/.config/lean-conky-config ~/.config/lean-conky-config.old
lean-conky-config
cp ~/.config/lean-conky-config.old/local.conf ~/.config/lean-conky-config/
lean-conky-config
```

The first line moves your old copy aside. The second makes a new copy and
starts it. The third brings your `local.conf` back, and the fourth restarts
the panel with it. (No `local.conf` yet? Skip the last two lines.)

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

**Little squares instead of icons.** The font link is missing; restarting the
panel puts it back: `lean-conky-config`.

**Messages like `'out_to_wayland' is deprecated` or
`Fontconfig error: the ambiguous constant name: normal`.** Harmless: Conky and
fontconfig are newer than some settings the panel writes the old way.

**No weather.** It needs the internet. If it shows the wrong place, write your
city, as in the table above.

> 💡 The panel's own `tools/check-lcc` looks for programs where other Linux
> systems keep them, so on NixOS it reports some as missing that the panel
> has. `lean-conky-config` brings them all.
