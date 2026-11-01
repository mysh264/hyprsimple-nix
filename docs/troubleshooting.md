# When something goes wrong

Find what you see in the list below. Each one says what it means and what to
do.

> 🛟 **First, the safety net.** If your computer does not start properly after
> a rebuild, restart it. In the menu that appears while it starts, pick an
> older entry (one with a smaller "Generation" number). Your computer is back
> as it was before the last rebuild. Then fix the problem and rebuild again.

**Jump to:**
[The rebuild fails](#the-rebuild-fails) ·
[A command is "not found"](#a-command-is-not-found) ·
[hyprsimple-install complains](#hyprsimple-install-complains) ·
[Hyprland does not start](#hyprland-does-not-start) ·
[No bar at the top](#no-bar-at-the-top) ·
[The lock screen does not take my password](#the-lock-screen-does-not-take-my-password) ·
[No sound, Wi-Fi or Bluetooth](#no-sound-wi-fi-or-bluetooth) ·
[Prayer times are wrong or missing](#prayer-times-are-wrong-or-missing) ·
[Home Manager complains](#home-manager-complains) ·
[Asking for help](#asking-for-help)

---

## The rebuild fails

`sudo nixos-rebuild switch` stops with red text. Look for the first line
that starts with `error:`. Then find it here:

- **`syntax error, unexpected ...`**: a typing mistake in a file you
  changed. The message says which file and which line. The usual mistakes: a
  missing `;` at the end of a line, a missing `"`, or one `}` too many or too
  few. Compare with the examples in the [install guide](install.md).

- **`The option 'programs.hyprsimple' does not exist`**: NixOS does not know
  about hyprsimple-nix. In the classic setup, check the `fetchTarball` line in
  `imports`. With a flake, check that `hyprsimple-nix.nixosModules.default`
  is in your `modules` list.

- **`unable to download ...` or `Could not resolve host`**: no internet.
  Connect, and rebuild again.

- **`... has an unfree license ..., refusing to evaluate`**: you set up an
  NVIDIA card. Add `nixpkgs.config.allowUnfree = true;` (the
  [graphics guide](gpu.md)'s files have it).

- **`hyprsimple's configuration is written in Lua, which needs Hyprland 0.55
  or newer`**: your NixOS is too old. Update to NixOS 26.05 or newer.

- **With a flake: `path '.../gpu.nix' does not exist`**, even though the file
  is there: your `/etc/nixos` folder is a git repository, and git does not
  know the file yet. Type `sudo git -C /etc/nixos add gpu.nix` and rebuild.

## A command is "not found"

- **`hyprsimple-install: command not found`** (or `hyprsimple-nixos`): the
  rebuild in [step 2](install.md#step-2-rebuild) did not finish, or
  `programs.hyprsimple.enable = true;` is missing. Fix it, rebuild, and open a
  **new** terminal.

- **`hyprsimple-update: command not found`**: open a new terminal. If it still
  happens, run it as `~/.local/bin/hyprsimple-update.sh`.

## hyprsimple-install complains

- **`run hyprsimple-install as the user who will use hyprsimple, not as
  root`**: do not type `sudo` in front of it.

- **`this NixOS configuration does not enable hyprsimple`**: add
  `programs.hyprsimple.enable = true;` and rebuild.

- **`~/.local/share/hyprsimple has local changes`**: someone changed
  hyprsimple's own files there. hyprsimple-nix will not overwrite them. To
  throw those changes away, type `git -C ~/.local/share/hyprsimple reset --hard`
  and run it again.

- **`... are links into /nix/store, which usually means Home Manager owns
  them`**: see [Home Manager complains](#home-manager-complains).

- **It finishes with `Installed, but … need another go`**: it lists what did
  not work and the command to try again. The prayer times plugin needs
  internet; the user services need you to be logged in yourself (not through
  `su`).

## Hyprland does not start

You pick Hyprland, and get a black screen, or land back on the login screen.

1. **NVIDIA card?** Make sure you did the [graphics guide](gpu.md). Without
   it, Hyprland cannot start on NVIDIA.
2. **In a virtual machine?** Turn on 3D acceleration; see
   [Virtual machines](gpu.md#virtual-machines).
3. **Did you run `hyprsimple-install`?** Without it, Hyprland starts with its
   plain default look instead of hyprsimple.
4. **Still nothing?** Log in on a text screen (press **Ctrl + Alt + F2**) and
   type:

   ```sh
   journalctl --user -b | tail -n 60
   ```

   This shows the last messages from your session. Look for lines with
   `error`, and [ask for help](#asking-for-help) with them.

## No bar at the top

Press **Ctrl + ESC**: that hides and shows the bar. If it does not come back,
open a terminal (**SUPER + T**) and type:

```sh
~/.local/bin/hyprsimple-restart-bar.sh
```

## The lock screen does not take my password

Type your normal login password and press Enter. If it is never accepted,
the system's password check for the lock screen is missing: rebuild (it is
part of `programs.hyprsimple.enable`), then log out and in again.

**Locked out right now?** Press **Ctrl + Alt + F2** to get a text screen, log
in there, and type `sudo nixos-rebuild switch` (with `--flake ...` if you use
a flake), then `sudo reboot`. Anything you had not saved is lost, but you
are back in.

## No sound, Wi-Fi or Bluetooth

hyprsimple turns these on, but your own settings win. Check that your
configuration does not turn them off, like `networking.networkmanager.enable = false;`.

- **No sound?** Press **SUPER + S** and pick your speakers.
- **No Wi-Fi?** Press **SUPER + SHIFT + N** to see the networks.
- **No Bluetooth?** Press **SUPER + SHIFT + B**.

## Prayer times are wrong or missing

Your place is not set yet. Click the prayer time on the bar, and press **s**
for its settings. Or type:

```sh
muslimtify location set --auto
```

Don't want prayer times? See [Prayer times on the bar](settings.md#prayer-times-on-the-bar).

## Home Manager complains

hyprsimple changes its own files in `~/.config` all the time (for example,
every time you change themes). If Home Manager also manages those files,
the two fight.

**What to do:** in your Home Manager configuration, stop managing these:
`~/.config/hypr`, `~/.config/ghostty`, `~/.config/uwsm`, `~/.config/yazi`,
`~/.config/fastfetch`, `~/.config/starship.toml` and
`~/.config/pipewire`. Then run `hyprsimple-install` again.

**Home Manager manages your `.bashrc`?** Then hyprsimple cannot add its line
to it. Add it through Home Manager instead:

```nix
programs.bash.initExtra = "source ~/.local/bin/bashrc.sh";
```

## Asking for help

1. Type `hyprsimple-nixos status` and `hyprsimple-nixos gpu`, and copy what
   they print.
2. Type `hyprsimple-debug`. It makes a full report of your setup. Read it
   before you share it: it includes your computer's name and its list of
   programs.
3. Open an issue, and paste all of it:
   - Something with the **NixOS side** (installing, rebuilding, packages,
     graphics settings): [hyprsimple-nix issues](https://github.com/mysh264/hyprsimple-nix/issues)
   - Something with **hyprsimple itself** (the bar, themes, a key that does
     the wrong thing): [hyprsimple issues](https://github.com/rizukirr/hyprsimple/issues)

   Not sure which? Ask in hyprsimple-nix. We will send you on if needed.
