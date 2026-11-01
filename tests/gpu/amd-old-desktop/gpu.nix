# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: AMD Radeon HD 7870 GHz Edition.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # AMD graphics already works. This starts the AMD driver earlier,
  # so the screen looks right from the very start of the boot.
  hardware.amdgpu.initrd.enable = true;

  # Old AMD cards (Radeon HD 7000 and 8000, R7 and R9 200): use the newer amdgpu driver.
  hardware.amdgpu.legacySupport.enable = true;
}
