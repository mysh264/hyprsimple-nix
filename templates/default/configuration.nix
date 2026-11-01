# Your computer's settings. After changing anything, rebuild:
#   sudo nixos-rebuild switch --flake .#my-computer
{ pkgs, ... }:
{
  imports = [
    # Facts about this computer's disks and hardware. Make it on the computer with:
    #   nixos-generate-config --show-hardware-config > hardware-configuration.nix
    ./hardware-configuration.nix

    # Graphics settings. After the first rebuild, make the file with:
    #   hyprsimple-nixos gpu --file > gpu.nix
    # (if this folder is a git repository, also: git add gpu.nix)
    # then remove the # at the start of the next line, and rebuild again.
    # ./gpu.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # ---- hyprsimple ---------------------------------------------------------
  programs.hyprsimple = {
    enable = true;
    # Remove a # below to use that setting. More in docs/settings.md.
    # defaultTheme = "tokyo-night";          # the first theme
    # muslimtify.enable = false;             # no prayer times on the bar
    # excludePackages = [ pkgs.firefox ];    # apps you would rather not have
  };

  # A small login screen that starts hyprsimple. You can use any other login
  # screen instead, and pick "Hyprland (UWSM)" there. Without one, log in on
  # the text screen and type: uwsm start hyprland-uwsm.desktop
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
  };

  # ---- The rest of a normal NixOS configuration ---------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "my-computer"; # your computer's name
  time.timeZone = "UTC"; # for example "Europe/Berlin" or "Asia/Jakarta"

  # You. Set a password after the first rebuild with: sudo passwd me
  users.users.me = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # "wheel" lets you use sudo
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # The NixOS version this computer was first installed with. Do not change it
  # later, even after updating NixOS.
  system.stateVersion = "26.05";
}
