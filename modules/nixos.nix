{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.hyprsimple;

  hyprsimplePkgs = import ../pkgs { inherit pkgs; };

  mapping = import ./arch-packages.nix {
    inherit pkgs config;
    hyprsimplePkgs = hyprsimplePkgs // {
      inherit (cfg.qt) hyprqt6engine;
    };
  };

  excludedNames = map lib.getName cfg.excludePackages;
  isExcluded = p: builtins.elem (lib.getName p) excludedNames;
  keep = lib.filter (p: !isExcluded p);

  entryPackages = e: (e.packages or [ ]) ++ (e.fonts or [ ]);

  # Arch names whose every package was excluded, so hyprsimple's pacman
  # questions are answered "not installed" for them.
  excludedArchNames = lib.filter (
    name:
    let
      ps = entryPackages mapping.${name};
    in
    ps != [ ] && lib.all isExcluded ps
  ) (lib.attrNames mapping);

  providedArchNames = lib.attrNames mapping ++ lib.optional cfg.muslimtify.enable "muslimtify";

  # What hyprsimple's scripts run that Arch has from its base system or as a
  # dependency of something in packages.txt, so the lists never name it.
  runtimeDependencies = with pkgs; [
    adwaita-icon-theme # the Adwaita cursor two themes ask for
    curl # hyprsimple-debug's upload
    dbus # dbus-monitor (the bar's idle watch), dbus-update-activation-environment
    file
    glib # gsettings, used by the theme switcher
    gsettings-desktop-schemas
    pciutils # lspci, for the hardware checks
    pulseaudio # pactl; the sound server itself is PipeWire
    wirelesstools # iwconfig and iwlist, for the hotspot script
    xdg-utils
  ];
in
{
  options.programs.hyprsimple = {
    enable = lib.mkEnableOption ''
      hyprsimple, a minimal Hyprland desktop: a Quickshell bar, 40 themes
      with one-key switching, and in-place updates.

      This installs everything hyprsimple needs system wide. Each user then
      runs {command}`hyprsimple-install` once to get the configuration files'';

    package = lib.mkOption {
      type = lib.types.package;
      default = hyprsimplePkgs.hyprsimple;
      defaultText = lib.literalMD "hyprsimple from hyprsimple-nix";
      description = ''
        hyprsimple's files, prepared for NixOS, and the
        {command}`hyprsimple-install` and {command}`hyprsimple-nixos` tools.
        Its version is the hyprsimple version {command}`hyprsimple-update`
        delivers to users.
      '';
    };

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "deep-sea";
      example = "tokyo-night";
      description = ''
        The theme {command}`hyprsimple-install` applies first: the name of a
        directory in hyprsimple's {file}`.config/hypr/themes`. Users switch
        themes from the bar afterwards.
      '';
    };

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.firefox pkgs.neovim ]";
      description = ''
        Packages hyprsimple installs that you do not want, matched by name.
        The features that use them stop working, the way they would if you
        uninstalled them on Arch.
      '';
    };

    muslimtify = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Prayer times on the bar. hyprsimple installs its muslimtify plugin
          by default, so this does too: it installs muslimtify, and
          {command}`hyprsimple-install` adds the plugin from GitHub. A user
          can still remove it with {command}`hyprsimple-plugin remove muslimtify`.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = hyprsimplePkgs.muslimtify;
        defaultText = lib.literalMD "muslimtify from hyprsimple-nix";
        description = "The muslimtify package.";
      };
    };

    qt.hyprqt6engine = lib.mkOption {
      type = lib.types.package;
      default = hyprsimplePkgs.hyprqt6engine;
      defaultText = lib.literalMD "hyprqt6engine from hyprsimple-nix";
      description = ''
        The Qt platform theme hyprsimple selects (QT_QPA_PLATFORMTHEME in
        {file}`~/.config/uwsm/env`). It has to be built against the same Qt
        as your applications, which the default is.
      '';
    };

    localsend.openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open TCP and UDP port 53317 for LocalSend, as hyprsimple's installer
        does in ufw. NixOS's own firewall takes ufw's place.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.versionAtLeast config.programs.hyprland.package.version "0.55";
        message = ''
          hyprsimple's configuration is written in Lua, which needs Hyprland
          0.55 or newer, and programs.hyprland.package is
          ${config.programs.hyprland.package.version}.
        '';
      }
    ];

    # ---- The session ------------------------------------------------------

    programs.hyprland = {
      enable = true;
      # hyprsimple starts everything with `uwsm app` and logs out with
      # `uwsm stop`, so it needs the UWSM session.
      withUWSM = true;
    };

    # hyprlock needs a PAM service to check passwords. This is what
    # programs.hyprlock would add, without also enabling services.hypridle:
    # hyprsimple starts hypridle itself, and two would lock and dim twice.
    security.pam.services.hyprlock = { };

    security.polkit.enable = true; # hyprpolkitagent
    programs.dconf.enable = true; # gsettings, which the theme switcher writes
    # QT_PLUGIN_PATH for the system profile, where hyprqt6engine and Kvantum
    # live. No platform theme here: ~/.config/uwsm/env picks it.
    qt.enable = true;
    programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ]; # webp in GTK
    # The file chooser: xdg-desktop-portal-hyprland does not implement one.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # ---- What hyprsimple's installer enables on Arch ------------------------

    networking.networkmanager.enable = lib.mkDefault true; # the bar's network panel
    hardware.bluetooth.enable = lib.mkDefault true; # the bluetooth panel
    services.power-profiles-daemon.enable = lib.mkDefault (!config.services.tlp.enable);
    services.upower.enable = lib.mkDefault true; # battery status on the bar
    services.gvfs.enable = lib.mkDefault true; # nautilus: trash, network places
    services.udisks2.enable = lib.mkDefault true; # nautilus: removable drives
    services.resolved.enable = lib.mkDefault true; # the DNS setting in the system panel
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };
    networking.firewall = lib.mkIf cfg.localsend.openFirewall {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };

    # hyprsimple keeps its scripts in ~/.local/bin and calls them by name.
    environment.localBinInPath = lib.mkDefault true;

    # ---- Packages ---------------------------------------------------------

    environment.systemPackages =
      keep (lib.concatMap (e: e.packages or [ ]) (lib.attrValues mapping))
      ++ keep runtimeDependencies
      ++ [ cfg.package ]
      ++ lib.optional cfg.muslimtify.enable cfg.muslimtify.package;

    fonts.packages = keep (lib.concatMap (e: e.fonts or [ ]) (lib.attrValues mapping));

    # gsettings from a script only finds the schemas it writes when they are
    # on XDG_DATA_DIRS. Applications carry their own; the command does not.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    # User units these packages ship, which hyprsimple-install enables per
    # user, as hyprsimple's installer does with `systemctl --user enable`.
    systemd.packages = [
      pkgs.hyprpaper
      pkgs.hyprpolkitagent
      pkgs.hyprsunset
    ];
    # brightnessctl's udev rule, for backlights logind does not handle.
    services.udev.packages = [ pkgs.brightnessctl ];

    # ---- What hyprsimple-install and hyprsimple-update read ------------------

    environment.etc = {
      "hyprsimple/source".source = "${cfg.package}/share/hyprsimple";
      "hyprsimple/arch-packages".text = lib.concatLines providedArchNames;
      "hyprsimple/arch-packages-excluded".text = lib.concatLines excludedArchNames;
      "hyprsimple/shims/pacman".source = "${cfg.package}/libexec/hyprsimple-nix/shims/pacman";
      "hyprsimple/settings".text = ''
        HYPRSIMPLE_NIX_DEFAULT_THEME=${lib.escapeShellArg cfg.defaultTheme}
        HYPRSIMPLE_NIX_MUSLIMTIFY=${if cfg.muslimtify.enable then "1" else "0"}
      '';
    };
  };
}
