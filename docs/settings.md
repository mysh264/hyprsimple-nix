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

- **Hyprland**, the desktop itself, with its helpers.
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
      version = "0.4.5-unstable-2026-11-01";
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
`hyprctl reload` in a terminal. hyprsimple's own
[README](https://github.com/rizukirr/hyprsimple#readme) tells you much more.
