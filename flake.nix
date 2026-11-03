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
        # The maintainer's whole setup, hyprsimple-nix included (docs/mysh264.md).
        mysh264 = ./profiles/mysh264.nix;
      };

      # hyprsimple, hyprqt6engine and muslimtify, for use outside the module.
      # The mended Viewnior is only a package below: as an overlay it would
      # take the place of the Viewnior it is made from.
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
          inherit (p)
            hyprsimple
            hyprqt6engine
            lean-conky-config
            muslimtify
            viewnior
            ;
          default = p.hyprsimple;
        }
      );

      checks = forAllSystems (pkgs: import ./tests { inherit pkgs self; });

      templates.default = {
        path = ./templates/default;
        description = "A NixOS configuration with hyprsimple";
        welcomeText = ''
          # A NixOS configuration with hyprsimple

          Next steps:

          1. Make the hardware file, on the computer this is for:
             `nixos-generate-config --show-hardware-config > hardware-configuration.nix`
          2. Open `configuration.nix` and set your computer's name, time zone and user.
          3. Rebuild: `sudo nixos-rebuild switch --flake .#my-computer`
          4. Set up your graphics card: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
          5. As your user: `hyprsimple-install`

          The full guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/install.md
        '';
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
