{
  description = "NixOS with hyprsimple";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprsimple-nix = {
      url = "github:mysh264/hyprsimple-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, hyprsimple-nix, ... }:
    {
      # Rename "my-machine" to your hostname, then:
      #   sudo nixos-rebuild switch --flake .#my-machine
      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
        modules = [
          hyprsimple-nix.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
