# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: NVIDIA GeForce RTX 3060 Lite Hash Rate.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # NVIDIA graphics card: GeForce GTX 1600, RTX 2000 or newer.
  nixpkgs.config.allowUnfree = true; # NVIDIA's driver is not open source; this says that is OK
  services.xserver.videoDrivers = [ "nvidia" ]; # says "xserver", but this is what turns the driver on
  hardware.nvidia = {
    open = true; # these cards use NVIDIA's open kernel module
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # hyprsimple sets these on Arch when NVIDIA is the only graphics card.
  environment.sessionVariables = {
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
