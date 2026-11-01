# Installing hyprsimple on NixOS, step by step

This guide takes you from a normal NixOS computer to the hyprsimple desktop.
There are six steps. Do them in order, and read each one to the end before
you type anything.

| Step | What you do | How long |
|---|---|---|
| [1](#step-1-tell-nixos-about-hyprsimple-nix) | Tell NixOS about hyprsimple-nix | 5 minutes |
| [2](#step-2-rebuild) | Rebuild your system | 10 to 30 minutes |
| [3](#step-3-set-up-your-graphics-card) | Set up your graphics card | 5 minutes |
| [4](#step-4-set-up-hyprsimple-for-your-user) | Set up hyprsimple for your user | 1 minute |
| [5](#step-5-log-in-to-hyprland) | Log in | 1 minute |
| [6](#step-6-your-first-minutes) | Learn the first few keys | as long as you like |

> 🛟 **You cannot break your computer for good.** NixOS keeps every older
> version of your system. If something goes wrong after a rebuild, restart
> the computer. In the menu that appears while it starts, pick an older entry
> (one with a smaller "Generation" number). Your computer is back as it was.

---

## Before you start

Check these four things:

1. **You use NixOS 26.05 or newer.** Open a terminal and type:

   ```sh
   nixos-version
   ```

   It prints something like `26.05.20261030.1c89083 (...)`. The first two
   numbers are what matter. `26.05`, `26.11` or bigger is good. If yours is
   smaller, update NixOS first.

2. **You have internet.** The first rebuild downloads a few gigabytes.

3. **You know your password.** Some commands start with `sudo`. That means
   "do this as the administrator", and it asks for your password. When you
   type it, nothing shows on the screen. That is normal. Type it and press
   Enter.

4. **You have about 5 GB of free disk space.** Type `df -h /` and look at the
   number under `Avail`.

**How do I open a terminal?** A terminal is a window where you type commands.

- On GNOME: press the Windows key, type `Terminal`, press Enter.
- On KDE Plasma: press the Windows key, type `Konsole`, press Enter.
- No desktop yet (just text on a black screen)? You are already in one.

**How do I type a command?** Type it exactly as shown (or copy and paste it),
then press **Enter**. In a terminal, paste with **Ctrl + Shift + V**.

---

## Step 1: Tell NixOS about hyprsimple-nix

NixOS keeps all of its settings in text files. You will add a few lines to
them. First, find out which kind of setup you have. Type:

```sh
ls /etc/nixos
```

- If you see **`flake.nix`** in the list, you use a *flake*. Go to
  [Step 1B](#step-1b-you-use-a-flake).
- If you do **not** see `flake.nix`, go to
  [Step 1A](#step-1a-you-do-not-use-a-flake). This is the most common case.

> 💡 Some people keep their settings in another folder, like
> `~/nixos-config`. If that is you, use your folder everywhere this guide
> says `/etc/nixos`.

### Step 1A: You do not use a flake

You will change one file: `/etc/nixos/configuration.nix`.

**1. Open the file.** Type:

```sh
sudo nano /etc/nixos/configuration.nix
```

`nano` is a simple text editor that runs in the terminal. Move around with
the arrow keys. To find a word, press **Ctrl + W**, type the word, and press
Enter.

**2. Find the `imports` list.** It is near the top and looks like this:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
```

**3. Add one line to it.** Put this line right under
`./hardware-configuration.nix`:

```nix
      "${builtins.fetchTarball "https://github.com/mysh264/hyprsimple-nix/archive/main.tar.gz"}/modules/nixos.nix"
```

Now it looks like this:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${builtins.fetchTarball "https://github.com/mysh264/hyprsimple-nix/archive/main.tar.gz"}/modules/nixos.nix"
    ];
```

This line tells NixOS where to download hyprsimple-nix from.

**4. Turn hyprsimple on.** Go to the very end of the file. The last line is a
single `}`. Right above it, add this line:

```nix
  programs.hyprsimple.enable = true;
```

So the end of the file looks something like this:

```nix
  system.stateVersion = "26.05"; # Did you read the comment?

  programs.hyprsimple.enable = true;
}
```

**5. Save and close.** Press **Ctrl + O**, then **Enter**, to save. Press
**Ctrl + X** to close nano.

Now go to [Step 2](#step-2-rebuild).

### Step 1B: You use a flake

You will change two files: `flake.nix` and `configuration.nix`.

**1. Open `flake.nix`.** Type:

```sh
sudo nano /etc/nixos/flake.nix
```

**2. Make three small changes.** Your file looks a bit like the first example
below. The second example shows the same file after the changes. The new
parts are marked with `# ← new`.

Before:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.my-computer = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
      ];
    };
  };
}
```

After:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    hyprsimple-nix = {                             # ← new
      url = "github:mysh264/hyprsimple-nix";       # ← new
      inputs.nixpkgs.follows = "nixpkgs";          # ← new
    };                                             # ← new
  };

  outputs = { self, nixpkgs, hyprsimple-nix, ... }: {   # ← new: hyprsimple-nix,
    nixosConfigurations.my-computer = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        hyprsimple-nix.nixosModules.default       # ← new
      ];
    };
  };
}
```

In words:

- In `inputs`, add the four lines that say where hyprsimple-nix comes from.
- In the `outputs = { ... }` line, add `hyprsimple-nix,` to the list.
- In `modules`, add `hyprsimple-nix.nixosModules.default`.

You do not need to copy the `# ← new` notes. They are only there to show you
what changed.

**3. Save and close** (**Ctrl + O**, **Enter**, **Ctrl + X**).

**4. Turn hyprsimple on.** Open `configuration.nix`:

```sh
sudo nano /etc/nixos/configuration.nix
```

Go to the very end of the file. The last line is a single `}`. Right above
it, add:

```nix
  programs.hyprsimple.enable = true;
```

Save and close.

**5. Remember your configuration's name.** In `flake.nix` you saw
`nixosConfigurations.my-computer`. The word after the dot (here
`my-computer`) is its name. You need it in the next step.

---

## Step 2: Rebuild

"Rebuilding" means: NixOS reads your settings and makes them real. It
downloads hyprsimple, Hyprland and everything else it needs.

**If you followed Step 1A**, type:

```sh
sudo nixos-rebuild switch
```

**If you followed Step 1B**, type this, with your configuration's name
instead of `my-computer`:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#my-computer
```

The first time takes a while: often 10 to 30 minutes. Lots of text scrolls
by. That is normal. Wait until you can type again.

✅ **Did it work?** The last lines should not contain a red `error`. Then
type:

```sh
hyprsimple-nixos status
```

You should see `Provided by NixOS: hyprsimple` with a version number (like
`0.4.8`), and `Not set up for <your name> yet`. Good: that is what step 4
does.

❌ **Got an error?** Read the first line that says `error:`. Most often it is
a typing mistake in the file you changed: a missing `;`, `"` or `}`. Open the
file again and compare it with the examples above. If you are stuck, see
[When something goes wrong](troubleshooting.md#the-rebuild-fails).

---

## Step 3: Set up your graphics card

- **NVIDIA graphics:** you **must** do this, or Hyprland will not start.
- **Intel or AMD graphics:** this is optional, but makes videos smoother and
  laptops cooler.

Follow **[the easy way in the graphics guide](gpu.md#the-easy-way-let-the-computer-find-out)**.
It takes about 5 minutes and ends with a restart. Then come back here.

---

## Step 4: Set up hyprsimple for your user

NixOS installed hyprsimple for the whole computer. Now each person who wants
to use it sets it up for themselves, once.

**Log in as yourself** (not as `root`), open a terminal, and type:

```sh
hyprsimple-install
```

What happens:

1. If you already have settings for programs hyprsimple brings its own
   settings for (like `~/.config/hypr` or `~/.config/ghostty`), it shows you a
   list. It will **move them aside**, to a name ending in `.backup`. Nothing is
   deleted. Press **Enter** to say yes.
2. It copies hyprsimple's files into your home folder, makes your home
   folders (Documents, Downloads, Music, Pictures, Videos...), turns on its
   helper services, picks the first theme, and installs the prayer times
   plugin.

✅ **Did it work?** At the end you see, in green:

```
  hyprsimple is set up for <your name>
```

❌ **It says "Installed, but … need another go" in red?** It lists which steps,
and the command to run for each. The most common one is the prayer times
plugin, which needs internet. Run the command it shows.

---

## Step 5: Log in to Hyprland

**If you have a login screen** (where you click your name and type your
password):

1. Log out.
2. On the login screen, look for a small menu to pick the *session*. It is
   often a gear icon ⚙️ or a list in a corner of the screen.
3. Pick **Hyprland (UWSM)**.
4. Log in as usual.

**If you do not have a login screen** (you log in by typing your name on a
black screen), log in, then type:

```sh
uwsm start hyprland-uwsm.desktop
```

<details>
<summary>💡 Want a simple login screen? Click here.</summary>

Only do this if you have **no** login screen yet. Add these lines to
`configuration.nix`, right above the last `}`:

```nix
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
  };
```

Rebuild (as in step 2) and restart. From then on, a small login screen
starts Hyprland for you.
</details>

✅ **Did it work?** You see a bar at the top of the screen and a terminal
window. 🎉 Welcome to hyprsimple.

❌ **Black screen, or you are sent back to the login screen?** See
[When something goes wrong](troubleshooting.md#hyprland-does-not-start).

---

## Step 6: Your first minutes

In hyprsimple, you do most things with the keyboard. The **SUPER** key is the
one with the Windows logo on most keyboards (⌘ on Apple keyboards).

| Press | What happens |
|---|---|
| **SUPER + /** | Shows every key combination. Start here! |
| **SUPER + T** | Opens a terminal |
| **SUPER + A** | Opens the app menu |
| **SUPER + B** | Opens the web browser (Firefox) |
| **SUPER + F** | Opens the file manager |
| **SUPER + Q** | Closes the window you are in |
| **SUPER + 1** … **SUPER + 0** | Switches between 10 workspaces (like separate desks) |
| **SUPER + SHIFT + T** | Picks a different theme (colours and wallpaper) |
| **SUPER + SHIFT + W** | Picks a different wallpaper |
| **Print** | Takes a screenshot |
| **SUPER + SHIFT + L** | Locks the screen |
| **SUPER + ESC** | Power menu: shut down, restart, log out |

**Your screen looks too big or too small?** Your screen settings are in
`~/.config/hypr/monitors.lua`. Open it with `nano ~/.config/hypr/monitors.lua`.
It has examples for high-resolution screens. Remove the `--` in front of the
lines you want, and save. Then type `hyprctl reload` in a terminal to use the
change.

**Your keyboard is not a US keyboard?** Open `~/.config/hypr/input.lua` and
change it to this, with your country's layout code instead of `de`:

```lua
hl.config({
  input = {
    kb_layout = "de",
  },
})
```

Save, and type `hyprctl reload` in a terminal.

---

## What next?

- **Keep it up to date:** [Updating](update.md)
- **Change what NixOS installs:** [Changing settings](settings.md)
- **Something does not work:** [When something goes wrong](troubleshooting.md)
- **Remove it again:** [Removing hyprsimple](uninstall.md)
- **Everything about hyprsimple itself** (all the keys, themes, scripts):
  [hyprsimple's own README](https://github.com/rizukirr/hyprsimple#readme)
