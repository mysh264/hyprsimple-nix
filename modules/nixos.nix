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

  # What a fresh Arch install has, where hyprsimple's README expects it (Arch,
  # with "Hyprland" picked in archinstall), and a NixOS without a desktop
  # environment does not. Found by installing exactly that Arch system and
  # comparing it with this module's NixOS, command by command and service by
  # service. See docs/how-it-works.md.
  desktopBasics = with pkgs; [
    # The home folders and the file manager.
    xdg-user-dirs # Documents, Downloads, Music and the other home folders
    xdg-user-dirs-gtk # those folders in the file manager's sidebar
    gdk-pixbuf # previews of pictures (gdk-pixbuf-thumbnailer)
    glycin-thumbnailer # previews of SVG, HEIF, JPEG XL and more
    libgsf # previews of office documents
    ffmpegthumbnailer # previews of videos (not on Arch; hyprsimple records to ~/Videos)
    mpv # plays them; hyprsimple's window rules are written for mpv
    desktop-file-utils # update-desktop-database, for apps you add by hand
    gtk3 # gtk-launch
    libsecret # secret-tool, for the password keyring
    # Commands Arch's base system and archinstall's desktop profile bring.
    gettext # envsubst
    htop
    lm_sensors # sensors
    openssl
    psmisc # killall, fuser, pstree
    python3
    smartmontools # smartctl
    vim
    wget
  ];

  # A Lua string and a Lua list, for the settings written into Lua below.
  luaString = text: "\"" + lib.escape [ "\\" "\"" ] text + "\"";
  luaList = toLua: items: "{ " + lib.concatMapStringsSep ", " toLua items + " }";

  # What programs.hyprsimple adds to Hyprland's configuration: the settings,
  # then the code in hyprland.lua that acts on them. hyprsimple's own config
  # loads it (patch 0007), before the user's files in ~/.config.
  extrasOn =
    cfg.workspaces.names != [ ]
    || cfg.workspaces.apps != { }
    || cfg.groups.enable
    || cfg.i3.enable
    || cfg.keys.workspaces11and12.enable
    || cfg.keys.numpad.enable;

  # An app's window class, matched by a part of it, in any letter case.
  appRules = lib.concatLists (
    lib.mapAttrsToList (
      workspace: apps:
      map (app: {
        inherit workspace;
        class = "(?i).*" + lib.strings.escapeRegex app + ".*";
      }) apps
    ) cfg.workspaces.apps
  );
  luaAppRule = rule: "{ workspace = ${luaString rule.workspace}, class = ${luaString rule.class} }";

  # Viewnior's keys for swayimg and imv (programs.hyprsimple.viewniorKeys).
  # swayimg 5 is set up in Lua, swayimg 4 in an INI file. Delete moves a photo
  # to the trash with gio.
  withGio =
    file: builtins.replaceStrings [ "@gio@" ] [ "${pkgs.glib.bin}/bin/gio" ] (builtins.readFile file);
  swayimgLua = lib.versionAtLeast pkgs.swayimg.version "5";
  viewniorKeysFiles = {
    ${if swayimgLua then "xdg/swayimg/init.lua" else "xdg/swayimg/config"}.text = withGio (
      if swayimgLua then ./viewnior-keys/swayimg.lua else ./viewnior-keys/swayimg-4.ini
    );
    "imv_config".text = withGio ./viewnior-keys/imv.ini;
  };
  hyprlandLua = ''
    -- Written by hyprsimple-nix from programs.hyprsimple in your NixOS
    -- configuration. Change the settings there and rebuild: this file is
    -- replaced every time.
  ''
  + lib.optionalString extrasOn ''
    local nix = {
      names = ${luaList luaString cfg.workspaces.names},
      apps = ${luaList luaAppRule appRules},
      groups = ${lib.boolToString cfg.groups.enable},
      i3 = ${lib.boolToString cfg.i3.enable},
      i3_workspaces = ${luaList toString cfg.i3.workspaces},
      hy3 = ${luaString (lib.optionalString cfg.i3.enable "${cfg.i3.package}/lib/libhy3.so")},
      workspaces_11_12 = ${lib.boolToString cfg.keys.workspaces11and12.enable},
      numpad = ${lib.boolToString cfg.keys.numpad.enable},
    }

    ${builtins.readFile ./hyprland.lua}'';

  # hy3, the plugin behind the i3 layout, built for this system's Hyprland. A
  # plugin only loads into the Hyprland version it was built for, and nixpkgs'
  # hy3 is sometimes a version behind. hy3 tags a release for every Hyprland
  # version, so those are filled in here.
  hy3Releases = {
    "0.57" = {
      version = "0.57.0";
      hash = "sha256-9qAw3Xsa0xN9b5ERiWEGL1fBq37GLskcrBj/6ax8PU4=";
    };
  };
  hy3Default =
    let
      hyprland = config.programs.hyprland.package;
      hy3 = (pkgs.hyprlandPlugins.override { inherit hyprland; }).hy3;
      wanted = lib.versions.majorMinor hyprland.version;
      release = hy3Releases.${wanted};
    in
    if lib.versions.majorMinor hy3.version == wanted || !(hy3Releases ? ${wanted}) then
      hy3
    else
      hy3.overrideAttrs {
        inherit (release) version;
        src = pkgs.fetchFromGitHub {
          owner = "outfoxxed";
          repo = "hy3";
          tag = "hl${release.version}";
          inherit (release) hash;
        };
      };

  # The "Hyprsimple" login entry exactly as hyprsimple-session.sh writes it
  # (the package keeps a copy), with uwsm's full path, as in Hyprland's own
  # entries on NixOS. It is in the system profile too, so that
  # `uwsm start hyprsimple.desktop` finds it.
  loginEntry =
    let
      uwsm = lib.getExe config.programs.uwsm.package;
    in
    pkgs.runCommand "hyprsimple-login-entry" { passthru.providedSessions = [ "hyprsimple" ]; } ''
      mkdir -p $out/share/wayland-sessions
      sed -e 's|^Exec=uwsm |Exec=${uwsm} |' -e 's|^TryExec=uwsm$|TryExec=${uwsm}|' \
        ${cfg.package}/share/hyprsimple-nix/wayland-sessions/hyprsimple.desktop \
        > $out/share/wayland-sessions/hyprsimple.desktop
      grep -qx 'Exec=${uwsm} start .*' $out/share/wayland-sessions/hyprsimple.desktop
      grep -qx 'TryExec=${uwsm}' $out/share/wayland-sessions/hyprsimple.desktop
    '';
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

    workspaces.names = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[^\n]+");
      default = [ ];
      example = [
        "Web"
        "Code"
        "Term"
      ];
      description = ''
        Names for workspaces 1, 2, 3 and so on, in that order. The bar shows
        each name instead of the workspace's dot, and always shows these
        workspaces, also while they are empty.
      '';
    };

    workspaces.apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.strMatching "[^\n]+"));
      default = { };
      example = lib.literalExpression ''
        {
          "1" = [ "firefox" "brave" "zen" "chrome" "chromium" ];
          "6" = [ "mpv" ];
        }
      '';
      description = ''
        Apps that always open on a workspace: the workspace's number, and the
        apps for it. An app is a part of its window class, in any letter
        case (`hyprctl clients` shows the class), so "firefox" also matches
        "org.mozilla.firefox".
      '';
    };

    groups.enable = lib.mkEnableOption ''
      keys for Hyprland's window groups: windows stacked in one place with a
      tab for each. SUPER + G groups the window you are on,
      SUPER + ALT + an arrow moves a window into the group there, and
      SUPER + ALT + TAB goes to the next window in the group. The tabs follow
      the theme'';

    i3 = {
      enable = lib.mkEnableOption ''
        the i3 layout next to Hyprland's own: windows in tabs and splits,
        the way i3 arranges them, with the hy3 plugin. SUPER + CTRL + SPACE
        switches the workspace you are on between the two. On an i3
        workspace, new windows become tabs, a lone window fills the screen
        without a tab bar, and SUPER + CTRL + H, J and E split like i3'';
      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.ints.positive;
        default = [ ];
        example = [
          2
          3
        ];
        description = ''
          Workspaces that start in the i3 layout. The others start in
          Hyprland's, and SUPER + CTRL + SPACE switches any of them.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = hy3Default;
        defaultText = lib.literalMD "hy3 for `programs.hyprland.package`";
        description = ''
          The hy3 plugin. It has to be built for the Hyprland you run, which
          the default is.
        '';
      };
    };

    bar.workspaceWidth = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 65;
      description = ''
        The width of every workspace on the bar, in pixels: all the same.
        Without it, a workspace with a name is as wide as its name, and one
        without as wide as its dot. A name too long for the width ends in
        "…". A change shows at the next login.
      '';
    };

    keys.workspaces11and12.enable = lib.mkEnableOption ''
      keys for workspaces 11 and 12, after SUPER + 1 to 0: SUPER + - goes to
      workspace 11 and SUPER + = to workspace 12, and with SHIFT they move the
      window you are on there. They are the two keys after 0 on the
      keyboard, whatever its layout'';

    keys.numpad.enable = lib.mkEnableOption ''
      the number pad as workspace keys, set up the way many i3 users have
      it: 4 and 6 go to the workspace before and after, 8 to the first
      workspace and 2 to the last, 5 and 0 back to the workspace you were on
      before, 1 and 3 move the focus left and right, 7 and 9 move the window
      left and right, and SHIFT + 1 to 9 go to that workspace (SHIFT + 0 to
      workspace 10). With this, the number pad no longer types numbers'';

    viewniorKeys.enable = lib.mkEnableOption ''
      Viewnior's keys and mouse in swayimg, hyprsimple's photo viewer, and in
      imv, which this installs as well: Space and Backspace for the next and
      the previous photo, + and - to zoom, 1 for 100%, f to fit the window,
      Ctrl+R to turn, h and v to flip, F11 for full screen, F5 for a
      slideshow, Delete to move a photo to the trash, Esc to close. A
      ~/.config/swayimg or ~/.config/imv/config file of your own is read
      instead'';

    viewnior.enable = lib.mkEnableOption ''
      Viewnior, the photo viewer, mended for Wayland. Unmended, it misses a
      touchpad's scrolling there (two fingers neither zoom nor turn to the
      next photo, only a mouse wheel does), a zoomed-in photo stands still
      when you drag it, and the crop dialog shows no rectangle. If
      pkgs.viewnior is installed as well, this one takes its place'';

    bar.position = lib.mkOption {
      type = lib.types.enum [
        "top"
        "bottom"
      ];
      default = "top";
      example = "bottom";
      description = ''
        Where hyprsimple's bar sits. At the bottom, its panels, notifications
        and tooltips open upwards out of it. A change shows at the next login.
      '';
    };

    loginEntry.enable = lib.mkEnableOption ''
      a "Hyprsimple" entry on the login screen, next to "Hyprland (UWSM)".
      It starts the same configuration; it changes the name you pick, and puts
      Hyprsimple into XDG_CURRENT_DESKTOP. This is what
      {command}`hyprsimple-session.sh` (or {command}`install.sh --session-entry`)
      adds on Arch. Text logins such as tuigreet's `--cmd` start it with
      {command}`uwsm start hyprsimple.desktop`'';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (n: builtins.match "[1-9][0-9]*" n != null) (lib.attrNames cfg.workspaces.apps);
        message = ''
          programs.hyprsimple.workspaces.apps takes workspace numbers, like
          "1" or "6", and ${toString (lib.attrNames cfg.workspaces.apps)} are not all numbers.
        '';
      }
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

    # NixOS 26.05 starts Hyprland through a wrapper that gives it the
    # cap_sys_nice capability. A program started that way loses TZDIR, the
    # place NixOS keeps time zones, and so does everything Hyprland starts:
    # the bar, terminals, every app. Then named time zones read as UTC, and
    # muslimtify showed "Asia/Dubai (UTC+0.0)" with prayer times hours early
    # (NixOS/nixpkgs#526193). nixos-unstable removed the wrapper with
    # Hyprland 0.57, and Arch never had it. Without it, Hyprland only cannot
    # give itself realtime priority, which it cannot on Arch either.
    security.wrappers.Hyprland.enable = lib.mkDefault false;

    services.displayManager.sessionPackages = lib.optional cfg.loginEntry.enable loginEntry;

    security.pam.services = lib.mkMerge [
      {
        # hyprlock needs a PAM service to check passwords. This is what
        # programs.hyprlock would add, without also enabling services.hypridle:
        # hyprsimple starts hypridle itself, and two would lock and dim twice.
        hyprlock = { };
      }
      # Unlock the password keyring when logging in through greetd, as the
      # text console's `login` already does.
      (lib.mkIf config.services.greetd.enable {
        greetd.enableGnomeKeyring = lib.mkDefault true;
      })
    ];

    security.polkit.enable = true; # hyprpolkitagent
    programs.dconf.enable = true; # gsettings, which the theme switcher writes
    # QT_PLUGIN_PATH for the system profile, where hyprqt6engine and Kvantum
    # live. No platform theme here: ~/.config/uwsm/env picks it.
    qt.enable = true;
    programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ]; # webp in GTK
    # The file chooser: xdg-desktop-portal-hyprland does not implement one.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # The accessibility bus. Arch always has it, with GTK; without it GTK apps
    # complain, and screen readers have nothing to talk to.
    services.gnome.at-spi2-core.enable = lib.mkDefault true;
    # A cursor for every program that does not choose one itself.
    xdg.icons.fallbackCursorThemes = lib.mkDefault [ "Adwaita" ];

    # ---- What a fresh Arch install has and a bare NixOS does not --------------

    # linux-firmware. Arch always installs it. Without it, AMD graphics,
    # most Wi-Fi cards and Bluetooth may not work at all.
    hardware.enableRedistributableFirmware = lib.mkDefault true;
    # A password keyring (the Secret Service), for programs that save
    # passwords: browsers based on Chromium, VS Code, git and others. On Arch
    # it comes along with the Hyprland profile (KWallet).
    services.gnome.gnome-keyring.enable = lib.mkDefault true;
    # The keyring's SSH agent is off on Arch, and it would collide with
    # programs.ssh.startAgent; keep it off unless you turn it on.
    services.gnome.gcr-ssh-agent.enable = lib.mkDefault false;
    # GnuPG and its agent: pacman needs them, so every Arch system has them.
    programs.gnupg.agent = {
      enable = lib.mkDefault true;
      pinentryPackage = lib.mkDefault pkgs.pinentry-gnome3;
    };
    # Search in the file manager, through its file index, as on Arch.
    services.gnome.localsearch.enable = lib.mkDefault true;
    services.gnome.tinysparql.enable = lib.mkDefault true;
    # HTTPS and proxy support for GTK and GLib programs.
    services.gnome.glib-networking.enable = lib.mkDefault true;
    # JACK programs on PipeWire, which archinstall's PipeWire choice installs.
    services.pipewire.jack.enable = lib.mkDefault true;
    # Programs that run in a terminal (btop, htop, yazi, nvim...) opened from
    # the app menu or the file manager. uwsm and GLib start them through
    # xdg-terminal-exec, which even Arch is missing.
    xdg.terminal-exec = {
      enable = lib.mkDefault true;
      settings.default = lib.mkDefault [ "com.mitchellh.ghostty.desktop" ];
    };
    # PDFs open in Firefox, as on Arch. NixOS's Firefox does not claim them.
    xdg.mime = lib.mkIf (!isExcluded pkgs.firefox) {
      defaultApplications."application/pdf" = lib.mkDefault "firefox.desktop";
      addedAssociations."application/pdf" = lib.mkDefault "firefox.desktop";
    };

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
      ++ keep desktopBasics
      ++ [ cfg.package ]
      ++ lib.optional cfg.muslimtify.enable cfg.muslimtify.package
      ++ lib.optional cfg.loginEntry.enable loginEntry
      # Ahead of a pkgs.viewnior in the same list, which has the same files.
      ++ lib.optional cfg.viewnior.enable (lib.hiPrio hyprsimplePkgs.viewnior)
      ++ lib.optional cfg.viewniorKeys.enable pkgs.imv;

    fonts.packages =
      keep (lib.concatMap (e: e.fonts or [ ]) (lib.attrValues mapping))
      # GTK's own interface fonts, Adwaita Sans and Adwaita Mono. Arch always
      # has them; without them GTK programs fall back to another font.
      ++ keep [ pkgs.adwaita-fonts ];

    # gsettings from a script only finds the schemas it writes when they are
    # on XDG_DATA_DIRS. Applications carry their own; the command does not.
    # Read by the bar (patch 0010).
    environment.sessionVariables.HYPRSIMPLE_BAR = lib.mkIf (cfg.bar.position == "bottom") "bottom";
    # Read by the bar (patch 0008).
    environment.sessionVariables.HYPRSIMPLE_BAR_WORKSPACE_WIDTH = lib.mkIf (
      cfg.bar.workspaceWidth != null
    ) (toString cfg.bar.workspaceWidth);

    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    # User units these packages ship, which hyprsimple-install enables per
    # user, as hyprsimple's installer does with `systemctl --user enable`.
    systemd.packages = [
      pkgs.hyprpaper
      pkgs.hyprpolkitagent
      pkgs.hyprsunset
      pkgs.xdg-user-dirs
    ];

    # The home folders (Documents, Downloads, Music, Pictures, Videos...),
    # created at every login and named in the user's language. Desktop
    # environments do this; without one, a home folder only gets the two that
    # hyprsimple-install makes.
    systemd.user.services.xdg-user-dirs.wantedBy = [ "graphical-session-pre.target" ];
    # And the same folders as bookmarks, so the file manager's sidebar and
    # file pickers list them. xdg-user-dirs-gtk only autostarts this on
    # GNOME, LXDE and Unity, so it is started here. It needs the display.
    systemd.user.services.xdg-user-dirs-gtk = {
      description = "User folders in the file manager's sidebar";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        "xdg-user-dirs.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.xdg-user-dirs-gtk}/bin/xdg-user-dirs-gtk-update";
      };
    };
    # brightnessctl's udev rule, for backlights logind does not handle.
    services.udev.packages = [ pkgs.brightnessctl ];

    # ---- What hyprsimple-install and hyprsimple-update read ------------------

    environment.etc = {
      "hyprsimple/source".source = "${cfg.package}/share/hyprsimple";
      "hyprsimple/arch-packages".text = lib.concatLines providedArchNames;
      "hyprsimple/arch-packages-excluded".text = lib.concatLines excludedArchNames;
      "hyprsimple/shims/pacman".source = "${cfg.package}/libexec/hyprsimple-nix/shims/pacman";
      "hyprsimple/shims/systemctl".source = "${cfg.package}/libexec/hyprsimple-nix/shims/systemctl";
      "hyprsimple/hyprland.lua".text = hyprlandLua;
      "hyprsimple/settings".text = ''
        HYPRSIMPLE_NIX_DEFAULT_THEME=${lib.escapeShellArg cfg.defaultTheme}
        HYPRSIMPLE_NIX_MUSLIMTIFY=${if cfg.muslimtify.enable then "1" else "0"}
      '';
    }
    // lib.optionalAttrs cfg.viewniorKeys.enable viewniorKeysFiles;
  };
}
