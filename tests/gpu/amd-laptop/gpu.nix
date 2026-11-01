# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: AMD Radeon 680M.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # AMD graphics already works. This starts the AMD driver earlier,
  # so the screen looks right from the very start of the boot.
  hardware.amdgpu.initrd.enable = true;
}
