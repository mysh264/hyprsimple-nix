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
[The file manager shows only Pictures and Videos](#the-file-manager-shows-only-pictures-and-videos) ·
[The lock screen does not take my password](#the-lock-screen-does-not-take-my-password) ·
[zoxide warns about its configuration](#zoxide-warns-about-its-configuration) ·
[A program other computers connect to does not work](#a-program-other-computers-connect-to-does-not-work) ·
[lan-mouse does not share the mouse](#lan-mouse-does-not-share-the-mouse) ·
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

## The file manager shows only Pictures and Videos

Your other home folders (Documents, Downloads, Music...) are missing. That
happened with the first version of hyprsimple-nix, on a NixOS without another
desktop. Update hyprsimple-nix and rebuild (see [Updating](update.md), part
1), then log out and in again. The folders appear, and the file manager lists
them in its sidebar.

Your folders are named in your language, and a folder you delete on purpose
stays deleted. To make them again anyway, type `xdg-user-dirs-update`.

## The lock screen does not take my password

Type your normal login password and press Enter. If it is never accepted,
the system's password check for the lock screen is missing: rebuild (it is
part of `programs.hyprsimple.enable`), then log out and in again.

**Locked out right now?** Press **Ctrl + Alt + F2** to get a text screen, log
in there, and type `sudo nixos-rebuild switch` (with `--flake ...` if you use
a flake), then `sudo reboot`. Anything you had not saved is lost, but you
are back in.

## zoxide warns about its configuration

The first `cd` in a new terminal says:

```
zoxide: detected a possible configuration issue.
Please ensure that zoxide is initialized right at the end of your shell configuration file
```

This was a small mistake in hyprsimple itself (on Arch too): it set zoxide up
before starship, and zoxide wants to be last. hyprsimple-nix fixes it. Update
and rebuild (see [Updating](update.md)), run `hyprsimple-update`, and open a
new terminal.

## A program other computers connect to does not work

Like hyprsimple's firewall on Arch, NixOS's firewall stops other computers
from connecting to yours, except for LocalSend. A program that waits for
other computers needs its port opened. Its own documentation says which one.
For a program that uses UDP port 4242, add this to `configuration.nix`, and
rebuild:

```nix
  networking.firewall.allowedUDPPorts = [ 4242 ];
```

(For a TCP port, it is `allowedTCPPorts`.)

## lan-mouse does not share the mouse

[lan-mouse](https://github.com/feschber/lan-mouse) lets one mouse and
keyboard control two computers. It is not part of hyprsimple, but it works
with it: we tested two hyprsimple-nix computers on NixOS 26.05, and the mouse
of one moved the pointer of the other, and came back. When it does not work,
it is one of these four things. Check them in order.

**1. Both computers need lan-mouse 0.11 or newer.**

Type `lan-mouse --version` on both computers. lan-mouse 0.11 encrypts
everything it sends, and lan-mouse 0.10 cannot understand that, so a 0.10
and a 0.11 never connect. NixOS 26.05 comes with **0.10.0**. Arch, Windows,
macOS and nixos-unstable have 0.11.

To get 0.11 on NixOS 26.05, take lan-mouse from nixos-unstable. With a flake,
open `/etc/nixos/flake.nix`:

1. In `inputs`, add a line for nixos-unstable:

   ```nix
     nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
   ```

2. In the `outputs = { ... }` line, add `nixpkgs-unstable,` to the list. It
   then looks like `outputs = { self, nixpkgs, nixpkgs-unstable, hyprsimple-nix, ... }:`.

3. In the `modules = [ ... ]` list, add this:

   ```nix
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.lan-mouse
          ];
        })
   ```

No flake? Then instead, add this to the `environment.systemPackages` list in
`configuration.nix`:

```nix
    (import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
      system = pkgs.stdenv.hostPlatform.system;
    }).lan-mouse
```

Either way, take out the old `lan-mouse` you added before (usually in
`environment.systemPackages`), so only one is left. Rebuild, and check that
`lan-mouse --version` says 0.11.

**2. The computer that gets controlled must let lan-mouse in.**

lan-mouse uses UDP port 4242. Open it on the computer whose pointer you want
to move from the other one. On NixOS, add this to `configuration.nix`, and
rebuild:

```nix
  networking.firewall.allowedUDPPorts = [ 4242 ];
```

On Arch with hyprsimple (its firewall is ufw), type
`sudo ufw allow 4242/udp`. The computer that sends its mouse needs nothing
opened. To go both ways, open the port on both.

**3. The computer that gets controlled must trust the other one.**

Since 0.11, lan-mouse only takes orders from computers you said yes to. Each
computer has a long code, its *fingerprint*. You find it in lan-mouse's
window, under **General**, as **certificate fingerprint** (with a button to
copy it).

1. Open lan-mouse on both computers.
2. Push the mouse over to the other computer once (see 4 below).
3. The computer that gets controlled shows a window, **Unauthorized
   Device**, with the other computer's fingerprint. Check that it is the
   same code the other computer shows under **General**, and press
   **Authorize**.

No window came? Copy the code on the computer that sends its mouse. Then, on
the computer that gets controlled, press **Authorize** in lan-mouse's
window, and paste it there. To go both ways, do this in both directions.

**4. The first time, touch the edge twice.**

Push the mouse against the screen edge where the other computer is. The
first push only connects, and the pointer stays. Push again: now it goes
over. Press **Ctrl + Shift + SUPER + Alt** together to get your mouse back.

> 💡 lan-mouse may say that `org.freedesktop.portal.InputCapture` was not
> found. That is fine. On NixOS 26.05, Hyprland's portal does not offer it
> yet (nixos-unstable's does), so lan-mouse catches the mouse its other way,
> with a strip one pixel wide at the screen's edge. That is what our test
> used.

## No sound, Wi-Fi or Bluetooth

hyprsimple turns these on, but your own settings win. Check that your
configuration does not turn them off, like `networking.networkmanager.enable = false;`.

- **No sound?** Press **SUPER + S** and pick your speakers.
- **No Wi-Fi?** Press **SUPER + SHIFT + N** to see the networks.
- **No Bluetooth?** Press **SUPER + SHIFT + B**.

## Prayer times are wrong or missing

**The times are hours off, and `muslimtify location` says `UTC+0.0`**, even
though your timezone is right (for example `Asia/Dubai`)? That was a bug,
fixed in hyprsimple-nix. It came from two places: on NixOS 26.05, Hyprland
started in a way that hid the time zone information from every program, and
muslimtify could not find time zones without it. Update hyprsimple-nix and
rebuild (see [Updating](update.md), part 1), then restart your computer. The
right times come back by themselves; your settings stay as they are.

**No prayer times, or the wrong city?** Your place is not set yet. Click the
prayer time on the bar, and press **s** for its settings. Or type:

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
