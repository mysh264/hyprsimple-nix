# Removing hyprsimple

Changed your mind? No problem. Removing hyprsimple has two parts, the
opposite of installing:

1. **For each user:** take hyprsimple's files out of your home folder, and
   put your old settings back.
2. **For the computer:** take hyprsimple out of your NixOS configuration.

Do them in this order. Copy each block of commands exactly. They only touch
hyprsimple's own files.

---

## Part 1: For each user

**1. Open a terminal:** **SUPER + T**.

**2. Run hyprsimple's remover.** Copy and paste this, then press Enter:

```sh
hyprsimple-uninstall.sh
```

It shows what it will take out and what it will put back, and asks first.
Type `yes`, and press Enter.

> 💡 It says `command not found`? Then your hyprsimple is older than 0.4.9.
> Type `hyprsimple-update` first, and try again.

**3. Log out**, as it says at the end. The bar and its power menu are gone
already, so type this in the same terminal:

```sh
uwsm stop
```

What it did, for you to know:

- It took out hyprsimple's bar, its helper programs, its scripts in
  `~/.local/bin`, its plugins, and the line it added to your shell's
  settings.
- It put your old settings back: the ones hyprsimple moved aside, to names
  ending in `.backup`, when you installed it. Where you had none, it moved
  hyprsimple's away, to names ending in `.hyprsimple-removed`, so nothing is
  lost. A script or a setting you changed yourself is moved away the same
  way, not deleted.
- `~/.local/share/hyprsimple` is gone too, unless it held work of your own
  (a `git stash`, for example). Then it was moved away as well.

If something goes wrong halfway, it says what. Run it again once that is
fixed: it goes on where it stopped.

**Every user** who ran `hyprsimple-install` does Part 1.

---

## Part 2: For the computer

**1. Open your configuration:**

```sh
sudo nano /etc/nixos/configuration.nix
```

**2. Remove every line that starts with `programs.hyprsimple`.** For example
`programs.hyprsimple.enable = true;`.

**3. Remove hyprsimple-nix itself.**

- **No flake:** in the `imports` list, remove the line with
  `hyprsimple-nix/archive/main.tar.gz` in it.
- **With a flake:** in `/etc/nixos/flake.nix`, remove the `hyprsimple-nix`
  input (four lines), `hyprsimple-nix,` in the `outputs` line, and
  `hyprsimple-nix.nixosModules.default` in `modules`. These are the parts the
  [install guide](install.md#step-1b-you-use-a-flake) added.

> 💡 **Keep `./gpu.nix`** in your imports if you made one. Your graphics card
> still needs those settings, with any desktop.

**4. Save, close, and rebuild:**

```sh
sudo nixos-rebuild switch
```

(or with `--flake /etc/nixos#my-computer` if you use a flake).

**5. Restart the computer.** Done. 🎉

---

## What stays behind

A few small things are not hyprsimple's alone, so they stay:

- **Your dark or light mode choice** for GTK apps. Your other desktop's
  settings can change it.
- **Pictures** hyprsimple cached in `~/.cache` (like `current_wallpaper`).
  You can delete them, or leave them.
- **Muslimtify's settings** in `~/.config/muslimtify`, if you used prayer
  times.
- **Anything moved away**, with names ending in `.hyprsimple-removed`, and
  older backups with names like `hypr.backup.1793001234`. Look with
  `ls -d ~/.config/*.hyprsimple-removed* ~/.config/*.backup.*`, and delete
  them when you no longer want them.
