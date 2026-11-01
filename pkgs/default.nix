# The packages hyprsimple-nix adds, built with whichever nixpkgs is passed in.
# The NixOS module builds them with the system's own pkgs, so the Qt plugin
# (hyprqt6engine) always matches the Qt your applications use.
{ pkgs }:
{
  hyprsimple = pkgs.callPackage ./hyprsimple/package.nix { };
  hyprqt6engine = pkgs.qt6Packages.callPackage ./hyprqt6engine/package.nix { };
  muslimtify = pkgs.callPackage ./muslimtify/package.nix { };
  quickshell = pkgs.callPackage ./quickshell/package.nix { };
}
