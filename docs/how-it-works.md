# How it works

For the curious, and for anyone who wants to help with hyprsimple-nix. You
do not need any of this to use hyprsimple.

## The problem

hyprsimple is made for Arch Linux. Its installer, `install.sh`, does three
kinds of things:

1. It installs 84 packages with `pacman` and the AUR.
2. It turns on system services, like Bluetooth, with `sudo systemctl`.
3. It copies its settings and scripts into your home folder.

On NixOS, parts 1 and 2 cannot work this way. NixOS builds the whole system
from your configuration, so packages and services must be *described* there,
not installed by hand. And hyprsimple's scripts expect things NixOS does not
have, like `/bin/bash` and `/usr/lib`.

## The answer, in three pieces

### 1. A NixOS module (`modules/nixos.nix`)

The module is what `programs.hyprsimple.enable = true;` turns on. It
describes parts 1 and 2 the NixOS way:

- every package from hyprsimple's lists. The list of which NixOS package
  stands for which Arch package is in
  [`modules/arch-packages.nix`](../modules/arch-packages.nix);
- the services `install.sh` enables: NetworkManager, Bluetooth, PipeWire,
  power-profiles-daemon, and so on;
- a few things Arch has by default and NixOS does not, like the GNOME
  settings schemas that hyprsimple's theme switcher writes to;
- what a desktop environment would bring on a NixOS that has none: the home
  folders (with `xdg-user-dirs`, at every login), previews of pictures and
  videos in the file manager, a fallback mouse cursor, and the accessibility
  bus.

It also puts a few files in `/etc/hyprsimple`, for the tools below:

| File | What it is for |
|---|---|
| `/etc/hyprsimple/source` | the hyprsimple version this system provides |
| `/etc/hyprsimple/arch-packages` | the Arch package names this system provides |
| `/etc/hyprsimple/settings` | the module's settings, like the first theme |
| `/etc/hyprsimple/shims/pacman` | a stand-in for `pacman`, explained below |

### 2. hyprsimple, prepared for NixOS (`pkgs/hyprsimple`)

This is hyprsimple itself, at a fixed release, with small changes so it fits
NixOS:

- Scripts start with `#!/usr/bin/env bash` instead of `#!/bin/bash`.
- Places like `/usr/lib/ladspa` and `/usr/share/icons` point to where NixOS
  keeps those things.
- Two user services had a hard-coded list of folders to look for programs
  in. On NixOS those folders are empty, so the list is replaced.
- Four small patches, in [`pkgs/hyprsimple/patches`](../pkgs/hyprsimple/patches).
  Each one only does something when `/etc/hyprsimple/source` exists, so
  hyprsimple on Arch would behave exactly as before:
  1. `hyprsimple-update` takes the new version from your NixOS
     configuration, instead of downloading it with git.
  2. `hyprsimple-plugin` checks a plugin's packages against your NixOS
     configuration, instead of installing them with pacman.
  3. `hyprsimple-migrate` puts the pacman stand-in first in line, so that
     migrations written for Arch, which ask pacman "is this installed?", get
     a true answer from your NixOS configuration.
  4. `hyprsimple-debug` reports NixOS facts in its debug report.

Every change is checked when the package builds. If a new hyprsimple version
moves something, the build fails and says which change no longer fits,
instead of quietly shipping something broken.

### 3. The per-user tools (`hyprsimple-nixos`, `hyprsimple-install`)

- **`hyprsimple-install`** does part 3 of `install.sh`: it copies
  hyprsimple's files to `~/.local/share/hyprsimple`, copies the settings
  and scripts, turns on the user services, applies the first theme, and
  installs the default plugin.
- **`hyprsimple-nixos sync`** is what `hyprsimple-update` calls to bring in
  a new version.
- **`hyprsimple-nixos gpu`** looks at your graphics hardware, as
  `install.sh` does, and writes the NixOS settings for it.

`~/.local/share/hyprsimple` is a small git repository. Each version NixOS
delivers becomes one commit. That is how `hyprsimple-update` can still tell
you exactly which files a new version changed, just like on Arch, where it
compares git commits too.

## Packages nixpkgs does not have

- **[hyprqt6engine](https://github.com/hyprwm/hyprqt6engine):** makes Qt
  programs follow the theme. hyprsimple selects it. Built from its release
  plus one fix from its repository, so it builds against current Qt.
- **[muslimtify](https://github.com/muslimtify-org/muslimtify):** the prayer
  times. It sets itself up as a user service. On NixOS a program's path
  changes with every update, so a small patch makes that service point at
  the stable path `/run/current-system/sw/bin/muslimtify`.
- **Quickshell**, which draws the bar, comes from NixOS but is wrapped in
  two ways: it can show webp pictures (most wallpapers are webp), and it
  keeps the name `qs`, which hyprsimple uses to find its bar.

## How it is tested

```sh
nix flake check   # the virtual machine test needs KVM
```

- **Packages** build, and muslimtify's own tests pass.
- **The package list** matches hyprsimple's lists exactly. If hyprsimple adds
  a package, this check fails until someone adds it to
  `modules/arch-packages.nix`.
- **Scripts** pass shellcheck, and every hyprsimple script still parses
  after the changes.
- **Whole systems** with the module, with the
  [template](../templates/default), and with every `gpu.nix` from
  [`tests/gpu`](../tests/gpu) evaluate without errors.
- **`hyprsimple-nixos gpu`** writes exactly the expected `gpu.nix` for 13
  example computers, and the [graphics guide](gpu.md) shows those files as
  the tool writes them.
- **A virtual machine** boots NixOS with the module, and, as a normal user:
  runs `hyprsimple-install`; checks that every command hyprsimple's scripts
  use is there; starts Hyprland through UWSM; checks the bar, notifications
  and helper services; switches the theme; runs `hyprsimple-update` with
  nothing new and then with a changed version; and finally follows the
  [removal guide](uninstall.md) and checks that the old settings came back.

All of this runs on every change, on both NixOS 26.05 and nixos-unstable.

The virtual machine takes screenshots. This one is from right after the
theme switch: hyprsimple's bar with the next prayer time, and the theme's
notification showing its wallpaper. (The virtual machine has no graphics
card, so the wallpaper program itself cannot draw there.)

![hyprsimple on NixOS, in the test virtual machine](vm-test-tokyo-night.png)

## Moving to a new hyprsimple release

A robot checks for new hyprsimple releases every week. When there is one, it
opens a pull request with the new version and the result of the quick
checks. To finish it, or to do it by hand:

1. Set `version` and `hash` in
   [`pkgs/hyprsimple/package.nix`](../pkgs/hyprsimple/package.nix).
2. Build it: `nix build .#hyprsimple`. If a change no longer fits, the build
   says which. The patches are plain `git diff` output: make the same change
   on a copy of the new release, and save the new diff.
3. Check the packages: `nix build .#checks.x86_64-linux.package-mapping`
   lists any new ones. Add them to `modules/arch-packages.nix`.
4. Read what changed in hyprsimple's `install.sh`. A new step that touches
   the home folder belongs in `cmd_install` in
   [`hyprsimple-nixos.sh`](../pkgs/hyprsimple/hyprsimple-nixos.sh). A new
   system step belongs in the module.
5. Run the virtual machine test: `nix build -L .#checks.x86_64-linux.vm`.

## Where things are

| Path | What it is |
|---|---|
| `flake.nix` | the entry point: module, packages, checks, template |
| `modules/nixos.nix` | the NixOS module |
| `modules/arch-packages.nix` | Arch package → NixOS package |
| `pkgs/hyprsimple/` | hyprsimple for NixOS, its patches, and the `hyprsimple-*` tools |
| `pkgs/hyprsimple/gpu/` | the pieces `hyprsimple-nixos gpu` builds `gpu.nix` from |
| `pkgs/hyprqt6engine/`, `pkgs/muslimtify/`, `pkgs/quickshell/` | the extra packages |
| `templates/default/` | a starting configuration for new machines |
| `tests/` | all the checks above |
| `docs/` | these guides |
