# hyprsimple for NixOS

[![CI](https://github.com/mysh264/hyprsimple-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/mysh264/hyprsimple-nix/actions/workflows/ci.yml)

<img width="1920" height="1080" alt="hyprsimple (screenshot from its README)" src="https://github.com/user-attachments/assets/d7956807-db97-4db4-8b38-58d3a6fc0630" />

## What is this?

**[hyprsimple](https://github.com/rizukirr/hyprsimple)** is a beautiful,
ready-to-use desktop, made by [rizukirr](https://github.com/rizukirr). It has
a bar at the top, 40 colour themes you can switch with one key, and lots of
handy tools. It is built on Hyprland, and made for Arch Linux.

**hyprsimple-nix** lets you use it on **NixOS**. Think of hyprsimple as a
fully furnished room. hyprsimple-nix is the moving company that carries it
into your NixOS house, piece by piece, without breaking anything.

You get hyprsimple exactly as its author made it: the same bar, themes, keys
and scripts. Only the parts that NixOS needs done differently are changed.

> This is an unofficial project, not made by hyprsimple's author. Problems
> with the NixOS side go [here](https://github.com/mysh264/hyprsimple-nix/issues);
> problems with hyprsimple itself go
> [to hyprsimple](https://github.com/rizukirr/hyprsimple/issues).

## Is it for me?

- ✅ You use **NixOS 26.05** or newer (type `nixos-version` to check).
- ✅ Your computer has an **Intel or AMD processor**, like nearly every PC
  and laptop.
- ✅ Your graphics are **Intel, AMD or NVIDIA**. The
  [graphics guide](docs/gpu.md) covers each of them.
- ❓ ARM computers (Raspberry Pi, Apple Silicon): not tested yet.

## How to install it

Six steps. The [install guide](docs/install.md) explains each one slowly,
with examples:

1. **Tell NixOS about hyprsimple-nix.** You add a few lines to your NixOS
   configuration.
2. **Rebuild.** NixOS downloads and installs everything.
3. **Set up your graphics card.** The command `hyprsimple-nixos gpu` tells you
   exactly what your computer needs. (You must do this for NVIDIA.)
4. **Set up your user.** Type `hyprsimple-install`.
5. **Log in.** Pick **Hyprland (UWSM)** on the login screen.
6. **Have fun.** Press **SUPER + /** to see every key.

👉 **[Start the install guide](docs/install.md)**

## Guides

| Guide | What it helps you with |
|---|---|
| [Installing](docs/install.md) | Getting hyprsimple onto your computer, step by step |
| [Graphics cards](docs/gpu.md) | Intel, AMD, NVIDIA, and laptops with two graphics chips |
| [Updating](docs/update.md) | Getting new hyprsimple versions |
| [Changing settings](docs/settings.md) | Workspace names, window groups (tabs), leaving out apps, prayer times, your own keys and screens |
| [When something goes wrong](docs/troubleshooting.md) | Fixes for common problems, and how to ask for help |
| [Removing](docs/uninstall.md) | Taking hyprsimple off again, and getting your old settings back |
| [How it works](docs/how-it-works.md) | What hyprsimple-nix does behind the scenes, and how it is tested |

<details>
<summary><b>Quick version, for people who know Nix flakes</b></summary>

```nix
{
  inputs.hyprsimple-nix = {
    url = "github:mysh264/hyprsimple-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, hyprsimple-nix, ... }: {
    nixosConfigurations.my-computer = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        hyprsimple-nix.nixosModules.default
        { programs.hyprsimple.enable = true; }
      ];
    };
  };
}
```

Rebuild, run `hyprsimple-nixos gpu` for the graphics settings, then
`hyprsimple-install` as each user, and log in to **Hyprland (UWSM)**. New
machine? `nix flake init -t github:mysh264/hyprsimple-nix`. No flakes? See
[step 1A](docs/install.md#step-1a-you-do-not-use-a-flake).
</details>

## Is it tested?

Yes. Every change is tested on NixOS 26.05 and on nixos-unstable, in a
virtual machine that installs hyprsimple as a normal user, logs in to
Hyprland, uses it (folders, previews, terminal apps, copy and paste, themes),
updates, and removes it again. And to make sure nothing basic is missing,
hyprsimple-nix is compared with a real Arch install of hyprsimple, piece by
piece. See [How it works](docs/how-it-works.md#how-we-know-nothing-is-missing).

## Thanks

[hyprsimple](https://github.com/rizukirr/hyprsimple) is made by rizukirr.
[hyprqt6engine](https://github.com/hyprwm/hyprqt6engine) is made by Hypr
Development (BSD-3-Clause), and
[muslimtify](https://github.com/muslimtify-org/muslimtify) by muslimtify-org
(MIT).

The Nix code, scripts and patches in this repository are MIT licensed. They
do not cover hyprsimple itself, which has no license file yet:
hyprsimple-nix only downloads it from its GitHub page, the same way
`git clone` does, and does not share copies of it.
