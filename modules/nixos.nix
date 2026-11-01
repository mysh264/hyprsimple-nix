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

  # A Lua string, for the names put into Hyprland's configuration below.
  luaString = text: "\"" + lib.escape [ "\\" "\"" ] text + "\"";

  # What programs.hyprsimple adds to Hyprland's configuration. hyprsimple's
  # own defaults load it (patch 0007), before the user's files in ~/.config.
  hyprlandLua = lib.concatStringsSep "\n" (
    [
      ''
        -- Written by hyprsimple-nix from programs.hyprsimple in your NixOS
        -- configuration. Change the settings there and rebuild: this file is
        -- replaced every time.
      ''
    ]
    ++ lib.optional (cfg.workspaces.names != [ ]) (
      ''
        -- Workspace names (programs.hyprsimple.workspaces.names). The bar
        -- shows them, and always shows these workspaces.
      ''
      + lib.concatImapStrings (
        number: name:
        "hl.workspace_rule({ workspace = \"${toString number}\", default_name = ${luaString name} })\n"
      ) cfg.workspaces.names
    )
    ++ lib.optional cfg.groups.enable ''
      -- Window groups (programs.hyprsimple.groups.enable): windows stacked in
      -- one place, with a tab for each. SUPER + Q still closes only the window
      -- you are on; the rest of its group stays.
      hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Group Windows / Ungroup" })
      hl.bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Take Window out of Group" })
      for _, way in ipairs({
        { "LEFT", "l", "Left" }, { "RIGHT", "r", "Right" }, { "UP", "u", "Up" }, { "DOWN", "d", "Down" },
        { "H", "l", "Left" }, { "L", "r", "Right" }, { "K", "u", "Up" }, { "J", "d", "Down" },
      }) do
        hl.bind("SUPER + ALT + " .. way[1], hl.dsp.window.move({ into_group = way[2] }),
          { description = "Move Window into Group " .. way[3] })
      end
      hl.bind("SUPER + ALT + TAB", hl.dsp.group.next(), { description = "Next Window in Group" })
      hl.bind("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous Window in Group" })
      hl.bind("SUPER + ALT + mouse_down", hl.dsp.group.next(), { description = "Next Window in Group" })
      hl.bind("SUPER + ALT + mouse_up", hl.dsp.group.prev(), { description = "Previous Window in Group" })
      for index = 1, 9 do
        hl.bind("SUPER + ALT + " .. index, hl.dsp.group.active({ index = index }),
          { description = "Window " .. index .. " in Group" })
      end

      hl.config({
        -- SUPER + H and L go through a group's windows before leaving it,
        -- like the tabs of i3.
        binds = { movefocus_cycles_groupfirst = true },
        -- The tabs look like the bar: its font, and rounded pills. The
        -- colours come with the theme (patch 0009).
        group = {
          groupbar = {
            font_family = "JetBrainsMono Nerd Font",
            font_size = 11,
            font_weight_active = "bold",
            height = 20,
            gaps_in = 4,
            gaps_out = 4,
            gradients = true,
            gradient_rounding = 5,
            gradient_round_only_edges = false,
            indicator_height = 0,
          },
        },
      })
    ''
  );

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

    groups.enable = lib.mkEnableOption ''
      keys for window groups: windows stacked in one place with a tab for
      each, the tabbed layout of i3. SUPER + G groups the window you are on,
      SUPER + ALT + an arrow moves a window into the group there, and
      SUPER + ALT + TAB goes to the next window in the group. The tabs follow
      the theme'';

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
      ++ lib.optional cfg.loginEntry.enable loginEntry;

    fonts.packages =
      keep (lib.concatMap (e: e.fonts or [ ]) (lib.attrValues mapping))
      # GTK's own interface fonts, Adwaita Sans and Adwaita Mono. Arch always
      # has them; without them GTK programs fall back to another font.
      ++ keep [ pkgs.adwaita-fonts ];

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
    };
  };
}
