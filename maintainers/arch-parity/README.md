# Comparing with Arch

hyprsimple is made and tested on Arch, so hyprsimple-nix tries to give NixOS
everything such an Arch system has. That is more than hyprsimple's package
lists: Arch's base system, the packages those packages pull in, and what
`archinstall` adds when you pick "Hyprland" (hyprsimple's README assumes
that) all bring things a NixOS without a desktop environment does not have.

These three files find those things. Run them after a new hyprsimple release,
or when someone reports something missing.

## 1. List what the Arch system has

You need Docker. This installs, in a throwaway Arch container, everything
hyprsimple's README expects: archinstall's desktop and Hyprland profiles, its
PipeWire and NetworkManager choices, and hyprsimple's own package lists (the
ones that are in Arch's official repositories).

```sh
src=$(nix build --no-link --print-out-paths .#hyprsimple)/share/hyprsimple
{
  sed -e 's/#.*//' -e 's/[[:space:]]//g' $src/packages.txt $src/aur-packages.txt
  echo nano vim openssh htop wget smartmontools xdg-utils          # archinstall: desktop
  echo hyprland dunst kitty uwsm dolphin wofi xdg-desktop-portal-hyprland \
       qt5-wayland qt6-wayland polkit-kde-agent grim slurp sddm    # archinstall: Hyprland
  echo pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire \
       libpulse wireplumber networkmanager                         # archinstall: audio, network
} | tr ' ' '\n' | grep -v '^$' | sort -u > /tmp/wanted.txt

docker run --rm -v /tmp:/work -v "$PWD/maintainers/arch-parity:/tools:ro" archlinux:base sh -c '
  pacman -Sy --noconfirm >/dev/null
  pacman -S --noconfirm --needed fontconfig $(for p in $(cat /work/wanted.txt); do
    pacman -Si "$p" >/dev/null 2>&1 && echo "$p"; done) >/dev/null
  sh /tools/arch-inventory.sh /work/arch.txt'
```

## 2. List what NixOS gets from the module

```sh
cp "$(nix build --impure --no-link --print-out-paths -f maintainers/arch-parity/nixos-inventory.nix)" /tmp/nixos.txt
```

## 3. Compare

```sh
python3 maintainers/arch-parity/diff.py /tmp/arch.txt /tmp/nixos.txt \
  dbus-session-services systemd-user autostart thumbnailers portals gio-modules applications
python3 maintainers/arch-parity/diff.py /tmp/arch.txt /tmp/nixos.txt bin
```

Everything printed is something only the Arch system has. Much of it is
harmless: helper programs of libraries nobody types, KDE parts that come with
archinstall's Dolphin, and things NixOS does in another way (programs on
NixOS carry their own plugins and settings with them). What is left is a gap,
to close in [`modules/nixos.nix`](../../modules/nixos.nix) and to check in
[the virtual machine test](../../tests/vm.nix).
