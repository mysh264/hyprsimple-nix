# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: NVIDIA GeForce RTX 3050 Mobile, AMD Radeon 680M.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # AMD graphics already works. This starts the AMD driver earlier,
  # so the screen looks right from the very start of the boot.
  hardware.amdgpu.initrd.enable = true;

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
      amdgpuBusId = "PCI:101:0:0"; # the built-in graphics chip
      nvidiaBusId = "PCI:1:0:0"; # the NVIDIA card
    };
  };
}
