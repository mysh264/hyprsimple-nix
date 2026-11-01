# Changing settings

There are two kinds of settings:

1. **What your computer installs.** These go in your NixOS configuration,
   `/etc/nixos/configuration.nix`. After changing one, you rebuild.
2. **How your desktop looks and behaves.** These are hyprsimple's own files
   in your home folder, mostly in `~/.config/hypr`. You change them like any
   text file, and they work right away (sometimes after `hyprctl reload`).

This page is about the first kind. For the second kind, see
[your desktop's own settings](#your-desktops-own-settings) at the end.

---

## How to change a setting in your NixOS configuration

Every time, it is the same three steps:

1. Open the file: `sudo nano /etc/nixos/configuration.nix`
2. Add or change a line. Lines go inside the outer `{ }`, for example right
   above the last `}`. Every line ends with `;`.
3. Save (**Ctrl + O**, **Enter**), close (**Ctrl + X**), and rebuild:
   `sudo nixos-rebuild switch` (or with `--flake`, as in the
   [install guide](install.md#step-2-rebuild)).

---

## The settings

### Turn hyprsimple on

```nix
  programs.hyprsimple.enable = true;
```

This is the one you added while installing. It installs everything
hyprsimple needs. Set it to `false` (or remove it) to turn hyprsimple off; see
[Removing hyprsimple](uninstall.md) for the whole story.

### Choose the first theme

```nix
  programs.hyprsimple.defaultTheme = "tokyo-night";
```

The theme `hyprsimple-install` starts with. The normal one is `deep-sea`.
This only matters the first time a user runs `hyprsimple-install`. After
that, press **SUPER + SHIFT + T** to pick any theme you like, any time.

The theme names are the folder names in `~/.config/hypr/themes`, for example
`catppuccin`, `dracula`, `gruvbox`, `nord`, `rosepine` or `tokyo-night`.

### Leave out programs you do not want

hyprsimple comes with Firefox, Neovim, Ghostty, Nautilus and more. To leave
some out:

```nix
  programs.hyprsimple.excludePackages = [ pkgs.firefox pkgs.neovim ];
```

The things that use them stop working. For example, **SUPER + B** opens
Firefox; without Firefox it does nothing.

> 💡 Need `pkgs` for this? The first line of `configuration.nix` should list
> it: `{ config, pkgs, ... }:`. It usually does.

### Name your workspaces

```nix
  programs.hyprsimple.workspaces.names = [ "Web" "Code" "Term" "Files" ];
```

Your workspaces get names, in order: the first name is workspace 1, the
second is workspace 2, and so on. The bar at the top shows the names instead
of small dots, and it always shows the workspaces you named, even when they
are empty, so you always know where everything goes.

1. Add the line to `configuration.nix`, with your own names, and rebuild.
2. Type `hyprctl reload` (or log out and in). The names appear on the bar.

Good to know:

- **SUPER + 1** to **SUPER + 0** go to workspaces 1 to 10. A workspace after
  10 has no key, but you can click it on the bar, or scroll over the bar to
  walk through all of them. Want a key anyway? Add a line like this to
  `~/.config/hypr/bindings/applications.lua`:

  ```lua
  hl.bind("SUPER + F11", hl.dsp.focus({ workspace = "11" }), { description = "Workspace 11" })
  ```

- Naming workspaces the Hyprland way, with `hl.workspace_rule` and
  `default_name` in your own files in `~/.config/hypr`, works too. The bar
  shows those names the same way.

### Window groups (tabs)

```nix
  programs.hyprsimple.groups.enable = true;
```

A group is several windows stacked in one place, like the tabs in a web
browser: you see one window, and a bar of tabs above it shows the others. It
is the "tabbed" layout of i3. hyprsimple has no keys for groups; this line
adds them. The tabs take the colours of your theme.

1. Add the line to `configuration.nix`, and rebuild.
2. Type `hyprctl reload` (or log out and in).
3. Press **SUPER + /** to see the new keys among the others.

| Press | What happens |
|---|---|
| **SUPER + G** | The window you are on becomes a group, with a tab bar. Press it again to undo the group. |
| *(open a window)* | A window you open while you are in a group joins that group. |
| **SUPER + ALT + ←** (or →, ↑, ↓) | Moves the window you are on into the group on that side. **H, L, K, J** work too. |
| **SUPER + ALT + G** | Takes the window you are on out of its group. |
| **SUPER + ALT + TAB** | Next window in the group. Add **SHIFT** for the one before. The mouse wheel works too, with **SUPER + ALT**. |
| **SUPER + ALT + 1** … **9** | Window 1 … 9 of the group. |
| **SUPER + H** / **L** | Go through the group's windows first, then on to the windows next to it, like i3. |
| **SUPER + Q** | Closes the window you are on, and only that one. |

With the mouse: click a tab to see that window, click a tab with the middle
mouse button to close that window, and drag a window onto a group (hold
**SUPER** and the left mouse button) to put it in.

**Closing a window never closes the rest of its group.** It does not matter
which one you close, the first one or any other: the others stay, as a
group. Our tests check exactly that.

> 💡 One thing is not about groups. A program you start by typing its name
> in a terminal can belong to that terminal, and then it closes when you
> close the terminal. To keep it open, start it from the app menu, or start
> it like this: `setsid -f nautilus` (with your program instead of
> `nautilus`).

### Prayer times on the bar

hyprsimple shows prayer times on the bar, through a plugin called
muslimtify. It is on unless you turn it off:

```nix
  programs.hyprsimple.muslimtify.enable = false;
```

This stops it from being installed for **new** users. If you already ran
`hyprsimple-install`, also remove the plugin from your bar:

```sh
hyprsimple-plugin remove muslimtify
```

**To set your city for the prayer times,** click the prayer time on the bar
and press **s** for its settings. Or type, with your own city's numbers:

```sh
muslimtify location set --auto
```

`--auto` guesses your place from your internet connection. You can also
give it exactly: `muslimtify location set --lat=-6.2 --long=106.8 --timezone=Asia/Jakarta --city=Jakarta`.

### LocalSend

```nix
  programs.hyprsimple.localsend.openFirewall = false;
```

hyprsimple opens network port 53317 in the firewall, so that
[LocalSend](https://localsend.org) can send files between your devices. If
you do not use LocalSend, you can close it with this line.

### A "Hyprsimple" entry on the login screen

```nix
  programs.hyprsimple.loginEntry.enable = true;
```

Your login screen lists **Hyprland (UWSM)**, and with this line also
**Hyprsimple**. Both start exactly the same desktop. The new name is only a
label, the one hyprsimple's `install.sh --session-entry` adds on Arch.

1. Add the line to `configuration.nix`, and rebuild.
2. Log out. On a login screen with a list of sessions (SDDM, GDM, LightDM),
   pick **Hyprsimple**.
3. Do you log in with greetd and tuigreet, like the
   [install guide](install.md)'s example? That login has no list. It starts
   one command, the one after `--cmd`. Change that command to
   `uwsm start hyprsimple.desktop`:

   ```nix
     services.greetd.settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprsimple.desktop'";
   ```

   The same command starts it from a text console.

To take it away, remove the line (or set it to `false`) and rebuild. On NixOS,
hyprsimple's own `hyprsimple-session.sh` points here instead of changing
anything.

### Your graphics card

Graphics settings live in their own file, `gpu.nix`. See the
[graphics guide](gpu.md).

---

## What hyprsimple turns on for you

When you set `programs.hyprsimple.enable = true;`, your NixOS gets what
hyprsimple has on Arch: what its installer sets up, and also what a fresh
Arch install already had before hyprsimple came. (We check this by building
exactly that Arch system and comparing; see
[How it works](how-it-works.md#how-we-know-nothing-is-missing).) You do not
have to do anything, but it is good to know:

- **Hyprland**, the desktop itself, with its helpers. Hyprland starts as on
  Arch: NixOS 26.05 would start it through a special "capability" wrapper,
  which made every program in your session lose its time zone information
  (prayer times and clocks in other apps could be hours off).
  nixos-unstable has already dropped that wrapper; hyprsimple-nix turns it
  off on 26.05 too.
- **The apps and tools** hyprsimple uses: about 80 of them. They are listed in
  [`modules/arch-packages.nix`](../modules/arch-packages.nix).
- **Firmware** for graphics cards, Wi-Fi and Bluetooth chips.
- **Fonts** for the bar, the icons, GTK programs and many languages.
- **Wi-Fi** (NetworkManager), **Bluetooth**, **sound** (PipeWire, also for
  JACK programs), **battery** information, and **power modes**.
- **Your home folders**: Documents, Downloads, Music, Pictures, Videos and the
  others, made at every login in your language, and listed in the file
  manager's sidebar.
- **The file manager's extras**: USB sticks, the trash can, search, and
  previews of pictures, videos and documents.
- **Opening files**: PDFs open in Firefox, videos in mpv, pictures in
  swayimg. Programs that run in a terminal (btop, yazi, Neovim...) open in
  Ghostty, from the app menu or the file manager.
- **A password keyring**, so programs can remember your passwords, and
  **GnuPG**.
- **Everyday commands** an Arch system has: `htop`, `vim`, `wget`,
  `killall`, `python3`, `openssl`, `sensors`, `smartctl`, `gpg` and more.
- **A mouse cursor** for every program, and the **accessibility** service
  screen readers use.
- **The firewall port** for LocalSend.
- **The lock screen's password check.**

Most of these are *defaults*: if you set one yourself, your choice wins. For
example:

```nix
  services.tlp.enable = true;                   # TLP instead of power modes
  services.gnome.localsearch.enable = false;    # no file index for search
  services.gnome.gnome-keyring.enable = false;  # no password keyring
  programs.hyprsimple.excludePackages = [ pkgs.mpv pkgs.vim ];  # leave apps out
```

---

## Using hyprsimple's development version

> ⚠️ For experienced people. hyprsimple's author recommends the normal
> releases. The development version can break.

hyprsimple-nix uses hyprsimple's latest release. To use a newer, unreleased
version from hyprsimple's `main` branch instead, save this as a new file,
`/etc/nixos/hyprsimple-main.nix`, with a commit from
[hyprsimple's history](https://github.com/rizukirr/hyprsimple/commits/main):

```nix
{ options, pkgs, ... }:
{
  programs.hyprsimple.package =
    options.programs.hyprsimple.package.default.overrideAttrs {
      version = "0.4.8-unstable-2026-11-01";
      src = pkgs.fetchFromGitHub {
        owner = "rizukirr";
        repo = "hyprsimple";
        rev = "PUT-THE-COMMIT-HERE";
        hash = "";
      };
    };
}
```

Add `./hyprsimple-main.nix` to the `imports` list in `configuration.nix`, the
same way as [`gpu.nix`](gpu.md#step-3-tell-nixos-to-read-the-file), and
rebuild. It stops and prints the right `hash`; put it between the quotes and
rebuild again. If one of hyprsimple-nix's NixOS fixes does not fit the newer
version, the rebuild tells you which one.

---

## Your desktop's own settings

These are hyprsimple's files, in your home folder. hyprsimple never
overwrites your changes to them.

| To change | Edit this file |
|---|---|
| Screens (size, position, scaling) | `~/.config/hypr/monitors.lua` |
| Keyboard layout, mouse, touchpad | `~/.config/hypr/input.lua` |
| Your own key combinations | `~/.config/hypr/bindings/applications.lua` |
| Gaps, borders, animations | `~/.config/hypr/looknfeel.lua` |
| Programs that start when you log in | `~/.config/hypr/autostart.lua` |
| Your default terminal, browser, file manager | `~/.config/hypr/vars.lua` |

Each file explains itself with notes at the top. After saving, type
`hyprctl reload` in a terminal.

> ⚠️ Don't change the files in `~/.local/share/hyprsimple`. Those are
> hyprsimple's own, and `hyprsimple-update` replaces them with every new
> version. While they have changes of yours, it stops, and you get no
> updates. Put your changes in the files above instead. hyprsimple's own
[README](https://github.com/rizukirr/hyprsimple#readme) tells you much more.
