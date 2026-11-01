{ pkgs, ... }:
{
  imports = [
    # Generate this on the machine with: nixos-generate-config --show-hardware-config
    ./hardware-configuration.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # ---- hyprsimple -----------------------------------------------------------
  programs.hyprsimple = {
    enable = true;
    # defaultTheme = "tokyo-night";
    # muslimtify.enable = false;           # no prayer times on the bar
    # excludePackages = [ pkgs.firefox ];  # packages you would rather not have
  };

  # A login screen that starts "Hyprland (UWSM)". Any display manager works;
  # without one, log in on a TTY and run: uwsm start hyprland-uwsm.desktop
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
  };

  # ---- The rest of a normal NixOS configuration -------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "my-machine";
  time.timeZone = "UTC";

  users.users.me = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "26.05";
}
