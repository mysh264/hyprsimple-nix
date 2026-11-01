{
  description = "hyprsimple, the minimal Hyprland desktop, on NixOS";

  inputs = {
    # Only used for this flake's own packages and checks. The NixOS module
    # builds everything with your system's nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules = {
        hyprsimple = ./modules/nixos.nix;
        default = self.nixosModules.hyprsimple;
      };

      # hyprsimple, hyprqt6engine and muslimtify, for use outside the module.
      overlays.default =
        final: _prev:
        let
          p = import ./pkgs { pkgs = final; };
        in
        {
          inherit (p) hyprsimple hyprqt6engine muslimtify;
        };

      packages = forAllSystems (
        pkgs:
        let
          p = import ./pkgs { inherit pkgs; };
        in
        {
          inherit (p) hyprsimple hyprqt6engine muslimtify;
          default = p.hyprsimple;
        }
      );

      checks = forAllSystems (pkgs: import ./tests { inherit pkgs self; });

      templates.default = {
        path = ./templates/default;
        description = "A NixOS configuration with hyprsimple";
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
