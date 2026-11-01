{ pkgs, self }:
let
  inherit (pkgs) lib;
  p = import ../pkgs { inherit pkgs; };

  # The module's view of hyprsimple's package lists. Only the names are read.
  mappedNames = lib.attrNames (
    import ../modules/arch-packages.nix {
      inherit pkgs;
      config.boot.kernelPackages = pkgs.linuxPackages;
      hyprsimplePkgs = p;
    }
  );

  # The template's configuration.nix, minus its import of the
  # hardware-configuration.nix that `nixos-generate-config` writes.
  templateConfiguration =
    let
      configuration = import ../templates/default/configuration.nix;
    in
    lib.setFunctionArgs (args: builtins.removeAttrs (configuration args) [ "imports" ]) (
      lib.functionArgs configuration
    );

  evalTemplate = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    # The platform comes from nixpkgs.hostPlatform, as in the template.
    system = null;
    modules = [
      self.nixosModules.default
      templateConfiguration
      {
        nixpkgs.hostPlatform = lib.mkForce pkgs.stdenv.hostPlatform.system;
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
      }
    ];
  };

  # The machines in tests/gpu: what lspci says on each, whether it has a
  # battery, and the gpu.nix `hyprsimple-nixos gpu` must write for it.
  gpuCases = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./gpu));

  # The gpu.nix files the GPU guide shows in full.
  gpuDocumented = [
    "intel-laptop"
    "amd-desktop"
    "nvidia-desktop"
    "nvidia-older-desktop"
    "nvidia-laptop-intel"
  ];

  gpuSystem =
    case:
    import "${pkgs.path}/nixos/lib/eval-config.nix" {
      inherit (pkgs.stdenv.hostPlatform) system;
      modules = [
        self.nixosModules.default
        (./gpu + "/${case}/gpu.nix")
        {
          programs.hyprsimple.enable = true;
          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };
          system.stateVersion = "26.05";
        }
      ];
    };

  # A complete system with hyprsimple, instantiated but not built, so
  # evaluation errors in the module surface without downloading a desktop.
  evalSystem = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    inherit (pkgs.stdenv.hostPlatform) system;
    modules = [
      self.nixosModules.default
      {
        programs.hyprsimple.enable = true;
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        users.users.alice.isNormalUser = true;
        system.stateVersion = "26.05";
      }
    ];
  };
in
{
  inherit (p)
    hyprsimple
    hyprqt6engine
    muslimtify
    quickshell
    ;

  # Fails when hyprsimple lists a package modules/arch-packages.nix does not
  # map, or the mapping keeps one hyprsimple no longer lists.
  package-mapping =
    pkgs.runCommand "hyprsimple-package-mapping"
      {
        src = p.hyprsimple.src;
        mapped = lib.concatLines mappedNames;
        passAsFile = [ "mapped" ];
      }
      ''
        listed=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' $src/packages.txt $src/aur-packages.txt | grep -v '^$' | sort -u)
        mapped=$(sort -u "$mappedPath")
        missing=$(comm -23 <(echo "$listed") <(echo "$mapped"))
        stale=$(comm -13 <(echo "$listed") <(echo "$mapped"))
        status=0
        if [[ -n $missing ]]; then
          echo "hyprsimple lists packages modules/arch-packages.nix does not map:"
          echo "$missing" | sed 's/^/  /'
          status=1
        fi
        if [[ -n $stale ]]; then
          echo "modules/arch-packages.nix maps packages hyprsimple no longer lists:"
          echo "$stale" | sed 's/^/  /'
          status=1
        fi
        [[ $status == 0 ]] && touch $out
        exit $status
      '';

  # Our own scripts get shellcheck. Every script hyprsimple ships, patched,
  # must at least still parse.
  scripts =
    pkgs.runCommand "hyprsimple-nix-scripts"
      {
        nativeBuildInputs = [
          pkgs.shellcheck
          pkgs.bash
        ];
      }
      ''
        shellcheck --shell=bash \
          ${../pkgs/hyprsimple/hyprsimple-nixos.sh} \
          ${../pkgs/hyprsimple/pacman-shim.sh}
        tree=${p.hyprsimple}/share/hyprsimple
        for f in $tree/.local/bin/*.sh $tree/.local/bin/hyprsimple-plugin $tree/migrations/*.sh; do
          [[ $f == */zsh.sh ]] && continue
          bash -n "$f" || { echo "does not parse: $f"; exit 1; }
        done
        if grep -rlI '^#!/bin/bash' $tree --exclude-dir=test | xargs -r head -qn1 | grep -q '^#!/bin/bash'; then
          echo "a shipped script still starts with #!/bin/bash"; exit 1
        fi
        touch $out
      '';

  # The context is dropped so this depends on the evaluation, not the build.
  module-eval = pkgs.writeText "hyprsimple-module-eval" (
    builtins.unsafeDiscardStringContext evalSystem.config.system.build.toplevel.drvPath
  );
  template-eval = pkgs.writeText "hyprsimple-template-eval" (
    builtins.unsafeDiscardStringContext evalTemplate.config.system.build.toplevel.drvPath
  );

  # `hyprsimple-nixos gpu --file` writes exactly the expected gpu.nix for
  # every machine in tests/gpu.
  gpu-detect = pkgs.runCommand "hyprsimple-gpu-detect" { nativeBuildInputs = [ pkgs.diffutils ]; } ''
    for case in ${lib.concatStringsSep " " gpuCases}; do
      dir=${./gpu}/$case
      sys=$TMPDIR/sys-$case
      mkdir -p $sys/class/power_supply
      if [[ -e $dir/laptop ]]; then mkdir -p $sys/class/power_supply/BAT0; fi
      export HYPRSIMPLE_NIX_SYSFS=$sys HYPRSIMPLE_NIX_LSPCI_FILE=$dir/lspci
      ${p.hyprsimple}/bin/hyprsimple-nixos gpu --file >$TMPDIR/$case.nix
      diff -u $dir/gpu.nix $TMPDIR/$case.nix || { echo "gpu.nix for $case is not what tests/gpu/$case/gpu.nix expects"; exit 1; }
      ${p.hyprsimple}/bin/hyprsimple-nixos gpu >/dev/null
    done
    touch $out
  '';

  # Every one of those gpu.nix files is a valid part of a NixOS configuration.
  gpu-eval = pkgs.writeText "hyprsimple-gpu-eval" (
    lib.concatMapStringsSep "\n" (
      case:
      "${case} ${builtins.unsafeDiscardStringContext (gpuSystem case).config.system.build.toplevel.drvPath}"
    ) gpuCases
  );

  # Every relative link and #anchor in the README and docs/ leads somewhere.
  docs-links =
    pkgs.runCommand "hyprsimple-nix-docs-links" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        python3 ${./check-doc-links.py} ${self}
        touch $out
      '';

  # The GPU guide shows those files exactly as the tool writes them.
  gpu-docs = pkgs.runCommand "hyprsimple-gpu-docs" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 - ${../docs/gpu.md} ${./gpu} ${lib.concatStringsSep " " gpuDocumented} <<'EOF'
    import pathlib, sys
    guide = pathlib.Path(sys.argv[1]).read_text()
    for case in sys.argv[3:]:
        body = (pathlib.Path(sys.argv[2]) / case / "gpu.nix").read_text()
        if body not in guide:
            sys.exit(f"docs/gpu.md does not show tests/gpu/{case}/gpu.nix exactly")
    EOF
    touch $out
  '';
}
// lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
  vm = import ./vm.nix { inherit pkgs self; };
}
