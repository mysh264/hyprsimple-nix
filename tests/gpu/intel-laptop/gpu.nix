# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: Intel UHD Graphics 620.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # Intel graphics. Lets videos play on the graphics chip, so they use less power.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # Intel chips from 2015 and newer
    intel-vaapi-driver # older Intel chips
  ];

  # Keeps an Intel laptop cool and quiet. hyprsimple turns this on for Intel laptops too.
  services.thermald.enable = true;
}
