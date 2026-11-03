# mysh264's setup: everything the maintainer of hyprsimple-nix uses, in one
# file. docs/mysh264.md explains each line, and how to put this whole setup on
# a new computer with one line. docs/shortcuts-mysh264.md lists every key.
#
# Each setting is a default (lib.mkDefault): one of your own, set in your
# configuration.nix, wins over it. extraConfig is the exception: your lines
# are added to these.
{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  # hyprsimple-nix itself, so that importing this file is all it takes.
  # (Importing the module as well does no harm: NixOS loads it once.)
  imports = [ ../modules/nixos.nix ];

  programs.hyprsimple = {
    enable = mkDefault true;

    # Names on the bar for workspaces 1 to 12, every one the same width, and
    # the bar at the bottom of the screen.
    workspaces.names = mkDefault [
      "Web"
      "Code"
      "Term"
      "Edit"
      "Files"
      "Videos"
      "Photos"
      "Theater"
      "Game"
      "Chat"
      "Music"
      "Lab"
    ];
    bar.workspaceWidth = mkDefault 65;
    bar.position = mkDefault "bottom";

    # Apps that always open on their own workspace. (Not Zen: "zen" would
    # also catch zenity's small dialog windows and zenmap.)
    workspaces.apps = mkDefault {
      "1" = [
        "firefox"
        "brave"
        "chrome"
        "chromium"
      ];
      "2" = [
        "claude"
        "cursor"
      ];
      "4" = [
        "kate"
        "gedit"
      ];
      "6" = [ "mpv" ];
      "7" = [
        "viewnior"
        "swayimg"
        "imv"
      ];
      "8" = [ "jellyfin" ];
      "9" = [ "steam" ];
    };

    # Keys: workspaces 11 and 12, the number pad, and the i3-style keys.
    keys.workspaces11and12.enable = mkDefault true;
    keys.numpad.enable = mkDefault true;
    keys.i3Style.enable = mkDefault true;

    # Window groups (tabs), and the i3 layout, with workspaces 2 and 3
    # starting in it.
    groups.enable = mkDefault true;
    i3.enable = mkDefault true;
    i3.workspaces = mkDefault [
      2
      3
    ];

    # The drop-down terminal, on the number pad's dot and the mouse's forward
    # button.
    dropdownTerminal.enable = mkDefault true;
    dropdownTerminal.keys = mkDefault [
      "code:91"
      "mouse:276"
    ];

    # Hot corners, as on Omarchy: top left hides or shows the bar, top right
    # shows the desktop, bottom right goes back to the workspace before.
    corners.enable = mkDefault true;

    # The Conky panel on the desktop.
    conky.enable = mkDefault true;

    # The prayer time on the right of the bar.
    muslimtify.placement = mkDefault "right";

    # Viewnior mended for Wayland, and Viewnior's keys in swayimg and imv.
    viewnior.enable = mkDefault true;
    viewniorKeys.enable = mkDefault true;

    # Small gaps between windows, none at the screen's edge, and a thicker
    # border.
    extraConfig = ''
      hl.config({ general = { gaps_in = 5, gaps_out = 0, border_size = 3 } })
    '';
  };
}
