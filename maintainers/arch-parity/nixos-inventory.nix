# What the module installs, listed the same way as arch-inventory.sh lists an
# Arch system. Build with:
#   nix build --impure --no-link --print-out-paths -f maintainers/arch-parity/nixos-inventory.nix
let
  flake = builtins.getFlake "path:${toString ../..}";
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = pkgs.lib;
  sys = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      flake.nixosModules.default
      {
        programs.hyprsimple.enable = true;
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "x";
          fsType = "ext4";
        };
        users.users.alice.isNormalUser = true;
        system.stateVersion = "26.05";
      }
    ];
  };
  c = sys.config;
  sp = c.system.path;
  userUnits = c.environment.etc."systemd/user".source;
  dbusDirs = lib.concatMapStringsSep " " (p: "${p}") c.services.dbus.packages;
in
pkgs.runCommand "nixos-inventory" { } ''
  set +e
  sec() { echo "## $1"; }
  {
    sec bin; ls ${sp}/bin
    sec dbus-session-services; for d in ${dbusDirs} ${sp}; do ls $d/share/dbus-1/services 2>/dev/null; done | sort -u
    sec systemd-user; ls ${userUnits} | grep -v '\.wants$\|\.requires$' || true
    sec systemd-user-wants; for w in ${userUnits}/*.wants; do for u in $w/*; do echo "$(basename $w)/$(basename $u)"; done; done || true
    sec autostart; ls ${sp}/etc/xdg/autostart 2>/dev/null
    sec thumbnailers; ls ${sp}/share/thumbnailers 2>/dev/null
    sec portals; ls ${sp}/share/xdg-desktop-portal/portals ${sp}/share/xdg-desktop-portal 2>/dev/null
    sec gio-modules; ls ${sp}/lib/gio/modules 2>/dev/null; echo "GIO_EXTRA_MODULES=${
      toString (c.environment.sessionVariables.GIO_EXTRA_MODULES or "")
    }"
    sec qt6-plugins; (cd ${sp}/lib/qt-6/plugins 2>/dev/null && find -L . -name '*.so' | sort)
    sec qt5-plugins; (cd ${sp}/lib/qt-5.15/plugins 2>/dev/null && find -L . -name '*.so' | sort)
    sec gsettings-schemas; ls -d ${sp}/share/gsettings-schemas/* 2>/dev/null | xargs -n1 basename
    sec applications; ls ${sp}/share/applications
    sec icons; ls ${sp}/share/icons
    sec themes; ls ${sp}/share/themes 2>/dev/null
    sec polkit-actions; ls ${sp}/share/polkit-1/actions 2>/dev/null
    sec fonts; echo "${lib.concatMapStringsSep "\n" (p: p.name) c.fonts.packages}"
  } > $out
''
