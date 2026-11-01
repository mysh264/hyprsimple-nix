# Updating hyprsimple

hyprsimple gets new versions now and then: new themes, fixes, new features.
Getting one onto your computer has two parts:

1. **Your NixOS system gets the new version.** You do this by rebuilding.
2. **Your user gets the new version.** You do this with `hyprsimple-update`.

Why two parts? NixOS installs things for the whole computer, but hyprsimple
keeps its files in each user's home folder, so that you can change them.
`hyprsimple-update` carefully moves the new version into your home folder
without touching your own settings.

> 💡 **Which version do I have?** Type `hyprsimple-nixos status`. It shows the
> version your system provides and the version your user has.

---

## Part 1: Give your system the new version

### If you do not use a flake

Every time you rebuild, NixOS fetches the newest hyprsimple-nix (it checks at
most once an hour). To make sure it checks right now, rebuild like this:

```sh
sudo nixos-rebuild switch --option tarball-ttl 0
```

### If you use a flake

A flake remembers exactly which version of hyprsimple-nix you use, in a file
called `flake.lock`. To move it to the newest version, type:

```sh
cd /etc/nixos
sudo nix flake update hyprsimple-nix
```

This updates **only** hyprsimple-nix. (Plain `sudo nix flake update` would
update everything, including all of NixOS. That is fine too, just bigger.)

Then rebuild, with your configuration's name instead of `my-computer`:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#my-computer
```

---

## Part 2: Give your user the new version

As yourself (not root), type:

```sh
hyprsimple-update
```

It does what hyprsimple's own update does on Arch:

- copies the new version into `~/.local/share/hyprsimple`,
- refreshes hyprsimple's helper scripts in `~/.local/bin`,
- runs *migrations*: small, careful fixes the hyprsimple author writes for
  people who are updating,
- redraws your themes if their templates changed,
- restarts the bar if it changed, and reloads Hyprland.

✅ **Did it work?** The last line is `hyprsimple is up to date.` in green.

**It says "already what your NixOS configuration provides"?** Then there was
nothing new. Do Part 1 first.

**It lists files under "This update changed configs you have your own version
of"?** That means: hyprsimple improved a settings file that you have changed
yourself. hyprsimple never overwrites your changes. If you want the new
version of one of those files, run the command it shows, for example:

```sh
hyprsimple-refresh-config.sh starship.toml
```

It saves your version next to it first (ending in `.bak.` and a number) and
shows you the difference. Nothing is lost.

**Everyone on the computer** who uses hyprsimple runs `hyprsimple-update`
once, after the rebuild.

---

## How do I know when there is a new version?

- On GitHub, click **Watch** → **Custom** → **Releases** on
  [hyprsimple](https://github.com/rizukirr/hyprsimple) to hear about new
  hyprsimple versions.
- hyprsimple-nix follows them. A robot checks for new hyprsimple versions
  every week, and the new version usually arrives here within a week or two.
  Click **Watch** on [hyprsimple-nix](https://github.com/mysh264/hyprsimple-nix)
  too if you like.

## Things that are different from Arch

On Arch, `hyprsimple-update --stable` and `hyprsimple-update main` choose
which version to follow. On NixOS your configuration decides that, so these
say so and stop. To follow upstream's development version anyway, see
[Using hyprsimple's development version](settings.md#using-hyprsimples-development-version).
