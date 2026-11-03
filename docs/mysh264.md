# mysh264's setup

This is the setup of hyprsimple-nix's maintainer: hyprsimple with the bar at
the bottom, names on the workspaces, keys in i3's style, window groups and the
i3 layout, the number pad, a drop-down terminal, hot corners and the Conky
panel. Everything is in one file,
[`profiles/mysh264.nix`](../profiles/mysh264.nix), so **one line puts all of
it on any NixOS**: a new computer, or yours after a reinstall.

Use it as it is, change a few things, or read it as an example of a whole
setup.

**On this page:**
[What is in it](#what-is-in-it) ·
[Put it on a new computer](#put-it-on-a-new-computer) ·
[Change a part of it](#change-a-part-of-it) ·
[What is not in it](#what-is-not-in-it) ·
[Every key](#every-key)

---

## What is in it

| Setting | What you get | Guide |
|---|---|---|
| `workspaces.names` | Workspaces 1 to 12 named Web, Code, Term, Edit, Files, Videos, Photos, Theater, Game, Chat, Music, Lab | [Name your workspaces](settings.md#name-your-workspaces) |
| `bar.position`, `bar.workspaceWidth` | The bar at the bottom, every workspace 65 pixels wide | [The bar at the bottom](settings.md#the-bar-at-the-bottom) |
| `workspaces.apps` | Browsers on 1, Claude and Cursor on 2, Kate and gedit on 4, mpv on 6, the photo viewers on 7, Jellyfin on 8, Steam on 9 | [Apps on their own workspace](settings.md#put-apps-on-their-own-workspace) |
| `keys.i3Style` | Keys in i3's style: SUPER + arrows, SUPER + ENTER, SUPER + D... | [Keys in i3's style](settings.md#keys-in-i3s-style) |
| `keys.workspaces11and12`, `keys.numpad` | Keys for workspaces 11 and 12, and the number pad as workspace keys | [Keys for workspaces 11 and 12](settings.md#keys-for-workspaces-11-and-12), [The number pad](settings.md#the-number-pad) |
| `groups`, `i3` | Window groups (tabs), and the i3 layout, which workspaces 2 and 3 start in | [Window groups](settings.md#window-groups-tabs), [The i3 layout](settings.md#the-i3-layout-tabs-and-splits-like-i3) |
| `dropdownTerminal` | A drop-down terminal on the number pad's dot and the mouse's forward button | [A drop-down terminal](settings.md#a-drop-down-terminal) |
| `corners` | Hot corners: top left hides the bar, top right shows the desktop, bottom right goes back | [Hot corners](corners.md) |
| `conky` | The Conky panel on the desktop | [The Conky panel](conky.md) |
| `muslimtify.placement` | The prayer time on the right of the bar | [Prayer times on the bar](settings.md#prayer-times-on-the-bar) |
| `viewnior`, `viewniorKeys` | Viewnior mended for Wayland, and its keys in swayimg and imv | [Viewnior](settings.md#viewnior-the-photo-viewer-mended-for-wayland) |
| `extraConfig` | Gaps of 5 pixels between windows, none at the screen's edge, and a 3-pixel border | [Your own lines for Hyprland](settings.md#your-own-lines-for-hyprland) |

---

## Put it on a new computer

1. **Install NixOS.** Any NixOS 26.05 or newer, also one without a desktop.
2. **Open your configuration:** `sudo nano /etc/nixos/configuration.nix`
3. **Add one line to the `imports` list,** right under
   `./hardware-configuration.nix`:

   ```nix
         "${builtins.fetchTarball "https://github.com/mysh264/hyprsimple-nix/archive/main.tar.gz"}/profiles/mysh264.nix"
   ```

   So the list looks like this:

   ```nix
     imports =
       [ # Include the results of the hardware scan.
         ./hardware-configuration.nix
         "${builtins.fetchTarball "https://github.com/mysh264/hyprsimple-nix/archive/main.tar.gz"}/profiles/mysh264.nix"
       ];
   ```

   That line brings hyprsimple-nix and the whole setup. You do not need
   `programs.hyprsimple.enable = true;` as well: the setup has it.

4. **No login screen yet?** Add one, as in the
   [install guide's step 5](install.md#step-5-log-in-to-hyprland).
5. **Save, and rebuild:** `sudo nixos-rebuild switch`
6. **Set up your graphics card** with `hyprsimple-nixos gpu`, as in
   [step 3 of the install guide](install.md#step-3-set-up-your-graphics-card).
   That part is different on every computer, so it is not in the setup.
7. **Set up your user:** log in as yourself and type `hyprsimple-install`.
8. **Log in to Hyprland,** and everything is there.

**Using a flake?** Instead of step 3, add `hyprsimple-nix.nixosModules.mysh264`
to your `modules`, the same way the
[install guide's step 1B](install.md#step-1b-you-use-a-flake) adds
`nixosModules.default`.

**Later, to get what changed on GitHub,** rebuild with:

```sh
sudo nixos-rebuild switch --option tarball-ttl 0
```

`--option tarball-ttl 0` makes NixOS download hyprsimple-nix again, instead of
using the copy it got earlier that day. Then type `hyprsimple-update`.

---

## Change a part of it

Every line of the setup is a default: **a line of yours wins.** Put it in your
own `configuration.nix`, below the `imports`:

```nix
  programs.hyprsimple.bar.position = "top";       # the bar back at the top
  programs.hyprsimple.conky.enable = false;       # no Conky panel
  programs.hyprsimple.corners.topRight = "launcher";
```

A list of yours (like `workspaces.names`) takes the place of the setup's whole
list. Your own `extraConfig` lines are added to the setup's.

---

## What is not in it

| What | Where it goes |
|---|---|
| Your graphics card | `gpu.nix`, made by `hyprsimple-nixos gpu` on each computer |
| Your user, the computer's name, time zone, login screen | Your `configuration.nix`, as with any NixOS |
| Your own apps | Your `configuration.nix` (`environment.systemPackages`) |
| Changes you make by hand in `~/.config/hypr` | Only on that computer. To bring one along to every computer, put it in `extraConfig` |
| Your changes to the Conky panel (`~/.config/lean-conky-config/local.conf`) | Only on that computer: copy the file over |

---

## Every key

[Every shortcut in mysh264's setup](shortcuts-mysh264.md) lists every key,
mouse button, corner and touchpad action of this setup, one on each line. A
test checks that list against the keys Hyprland really has with the setup on.
