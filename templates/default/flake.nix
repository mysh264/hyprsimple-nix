{
  description = "NixOS with hyprsimple";

  inputs = {
    # Where NixOS itself comes from.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Where hyprsimple-nix comes from. "follows" makes it use the same NixOS.
    hyprsimple-nix = {
      url = "github:mysh264/hyprsimple-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, hyprsimple-nix, ... }:
    {
      # "my-computer" is this configuration's name. Rebuild with:
      #   sudo nixos-rebuild switch --flake .#my-computer
      nixosConfigurations.my-computer = nixpkgs.lib.nixosSystem {
        modules = [
          hyprsimple-nix.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
