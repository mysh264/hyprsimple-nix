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

**1. Leave Hyprland.** Log out (**SUPER + X**). Log in to another desktop, or
on a text screen. Then open a terminal.

**2. Stop hyprsimple's helper programs.** Copy and paste this, then press
Enter:

```sh
for unit in battery-monitor.timer hyprsimple-audio-autoswitch.service \
  hyprsunset.service hyprpaper.service hyprpolkitagent.service muslimtify.service; do
  systemctl --user disable --now "$unit"
done
```

If one of them says it does not exist, that is fine.

**3. Put your old settings back.** When you installed hyprsimple, it moved
your old settings aside, to names ending in `.backup`. This puts them back.
Where you had no settings before, it moves hyprsimple's away to a name
ending in `.hyprsimple-removed`, so nothing is lost:

```sh
cd ~/.config
for item in ~/.local/share/hyprsimple/.config/*; do
  name=$(basename "$item")
  [ "$name" = systemd ] && continue
  if [ -e "$name.backup" ]; then
    rm -rf "$name" && mv "$name.backup" "$name"
  elif [ -e "$name" ]; then
    mv "$name" "$name.hyprsimple-removed"
  fi
done
rm -f systemd/user/battery-monitor.service systemd/user/battery-monitor.timer \
  systemd/user/hyprsimple-audio-autoswitch.service systemd/user/muslimtify.service
rm -rf systemd/user/hyprsunset.service.d
cd
```

> 💡 If you installed more than once, you may also have older backups with
> names like `hypr.backup.1793001234`. Look with `ls -d ~/.config/*.backup*`.

**4. Remove hyprsimple's scripts and folders:**

```sh
for f in ~/.local/share/hyprsimple/.local/bin/*; do
  rm -f ~/.local/bin/"$(basename "$f")"
done
rm -rf ~/.local/share/hyprsimple ~/.local/share/hyprsimple-plugins \
  ~/.local/state/hyprsimple ~/.config/hyprsimple
```

**5. Take hyprsimple out of your shell.** hyprsimple added one line to your
shell's settings file. This removes it again:

```sh
sed -i '/hyprsimple shell init/d; /\.local\/bin\/\(bashrc\.sh\|zsh\.sh\|fish\.fish\)/d' \
  ~/.bashrc ~/.zshrc ~/.config/fish/config.fish 2>/dev/null
```

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
