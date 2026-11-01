# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: Intel Iris Xe Graphics, NVIDIA GeForce RTX 4060 Max-Q / Mobile.
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

  # Two graphics chips: the built-in one draws your desktop, and the NVIDIA card
  # (GTX 1600, RTX 2000 or newer) helps only programs you start with `nvidia-offload`.
  nixpkgs.config.allowUnfree = true; # NVIDIA's driver is not open source; this says that is OK
  services.xserver.videoDrivers = [ "nvidia" ]; # says "xserver", but this is what turns the driver on
  hardware.nvidia = {
    open = true; # these cards use NVIDIA's open kernel module
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.finegrained = true; # laptops: switches the NVIDIA card off when nothing uses it
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # gives you the `nvidia-offload` command
      intelBusId = "PCI:0:2:0"; # the built-in graphics chip
      nvidiaBusId = "PCI:1:0:0"; # the NVIDIA card
    };
  };
}
