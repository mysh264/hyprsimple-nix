# End to end: a NixOS machine with the module, a user who runs
# hyprsimple-install, a real Hyprland session started through UWSM, and an
# update to a changed hyprsimple version.
{ pkgs, self }:
let
  inherit (pkgs) lib;
  # The muslimtify plugin, so its install can run without network access.
  muslimtifyPlugin = pkgs.fetchFromGitHub {
    owner = "muslimtify-org";
    repo = "muslimtify-hyprsimple";
    rev = "0b3920f9f97860fd04ca4db1497ab163f7c20bc4";
    hash = "sha256-HFj/f17B6c+g6rHNUU4owW27a7eUsDcw3sCcT0X803Y=";
  };
  # For tests/pad.py, the pretend touchpad and mouse.
  python = pkgs.python3.withPackages (ps: [ ps.evdev ]);
in
pkgs.testers.runNixOSTest {
  name = "hyprsimple";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.default ];

      programs.hyprsimple.enable = true;
      programs.hyprsimple.loginEntry.enable = true;
      # Switched to partway through, the way a rebuild does it.
      specialisation.extras.configuration = {
        programs.hyprsimple.workspaces.names = [
          "Web"
          "Code"
          "Term"
        ];
        programs.hyprsimple.groups.enable = true;
        programs.hyprsimple.i3 = {
          enable = true;
          workspaces = [ 2 ];
        };
        programs.hyprsimple.bar.position = "bottom";
        programs.hyprsimple.bar.workspaceWidth = 65;
        programs.hyprsimple.workspaces.apps."8" = [ "mpv" ];
        programs.hyprsimple.keys.workspaces11and12.enable = true;
        programs.hyprsimple.keys.numpad.enable = true;
        programs.hyprsimple.viewnior.enable = true;
        programs.hyprsimple.viewniorKeys.enable = true;
        programs.hyprsimple.dropdownTerminal.enable = true;
        # The unmended one as well, which the mended one has to win over.
        environment.systemPackages = [ pkgs.viewnior ];
      };
      # mysh264's whole setup (profiles/mysh264.nix), switched to after the
      # extras: keys in i3's style, hot corners, the Conky panel and more.
      specialisation.mysh264.configuration = {
        imports = [ self.nixosModules.mysh264 ];
        environment.systemPackages = [ pkgs.viewnior ];
      };
      # hyprsimple ships setup for these two shells as well; test them too.
      programs.zsh.enable = true;
      programs.fish.enable = true;

      users.users.alice = {
        isNormalUser = true;
        password = "alice";
        extraGroups = [ "wheel" ];
      };
      # A real seat session on tty1, which is what Hyprland needs to start.
      services.getty.autologinUser = "alice";

      environment.etc."muslimtify-plugin".source = muslimtifyPlugin;
      environment.systemPackages = [ pkgs.wayland-utils ];
      # For the pretend touchpad and mouse.
      hardware.uinput.enable = true;

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        diskSize = 4096;
        # virtio-gpu gives Hyprland a DRM device; Mesa renders in software.
        qemu.options = [
          "-vga none"
          "-device virtio-gpu-pci"
        ];
      };
    };

  testScript =
    { nodes, ... }:
    ''
      import json
      import re
      import shlex
      import time

      def user(cmd, check=True):
          env = "export XDG_RUNTIME_DIR=/run/user/1000; "
          env += "[ -d /run/user/1000/hypr ] && export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1); "
          full = "su - alice -c " + shlex.quote(env + cmd)
          if check:
              return machine.succeed(full)
          return machine.execute(full)

      def dump_session():
          print(user("journalctl --user -b --no-pager -o short-monotonic | tail -n 200", check=False)[1])
          print(user("hyprctl instances 2>&1; hyprctl monitors 2>&1; hyprctl configerrors 2>&1", check=False)[1])
          print(user("tail -n 150 /run/user/1000/hypr/*/hyprland.log 2>&1", check=False)[1])
          # Hyprland writes a report of its own when it crashes.
          print(user("for r in ~/.cache/hyprland/hyprlandCrashReport*.txt; do [ -e \"$r\" ] && echo \"== $r\" && head -n 120 \"$r\"; done", check=False)[1])

      machine.wait_for_unit("multi-user.target")
      # The automatic login may not have begun yet, and then wait_for_unit
      # gives up at once on a unit with nothing queued: wait for it to start.
      machine.wait_until_succeeds("systemctl is-active user@1000.service", timeout=120)

      with subtest("the system provides what hyprsimple-install needs"):
          machine.succeed("test -d /etc/hyprsimple/source/default/quickshell")
          machine.succeed("grep -qx hyprland /etc/hyprsimple/arch-packages")
          machine.succeed("test -f /etc/systemd/user/hyprpaper.service")
          machine.succeed("test -f /etc/systemd/user/hyprsunset.service")
          machine.succeed("test -f /etc/pam.d/hyprlock")
          machine.succeed("test -e /run/current-system/sw/lib/ladspa/librnnoise_ladspa.so")
          machine.succeed("ls /run/current-system/sw/lib/qt-6/plugins/platformthemes/libhyprqt6engine.so")
          machine.succeed("test -x /run/current-system/sw/bin/hyprsimple-install")
          # What a desktop environment would bring: a fallback cursor, and
          # thumbnailers for pictures (webp too) and videos.
          machine.succeed("grep -q Inherits=Adwaita /run/current-system/sw/share/icons/default/index.theme")
          for thumbnailer in ("gdk-pixbuf-thumbnailer", "webp-pixbuf", "ffmpegthumbnailer",
                              "glycin-svg", "glycin-heif", "gsf-office"):
              machine.succeed(f"test -f /run/current-system/sw/share/thumbnailers/{thumbnailer}.thumbnailer")
          # What a fresh Arch install has and a bare NixOS does not.
          machine.succeed("test -d /run/current-system/firmware/amdgpu || test -d /run/current-system/firmware/lib/firmware/amdgpu")
          machine.succeed("fc-list | grep -q 'Adwaita Sans'")
          machine.succeed("grep -qx com.mitchellh.ghostty.desktop /etc/xdg/xdg-terminals.list")
          # No capability wrapper for Hyprland: it strips TZDIR from everything
          # the session starts, and time zones then read as UTC.
          machine.succeed("test ! -e /run/wrappers/bin/Hyprland")
          machine.succeed("test -x /etc/hyprsimple/shims/systemctl")
          # Nothing from programs.hyprsimple to add yet.
          machine.succeed("! grep -q '^hl\\.' /etc/hyprsimple/hyprland.lua")
          # The "Hyprsimple" login entry, for login screens and for
          # `uwsm start hyprsimple.desktop`.
          sessions = "${
            pkgs.lib.concatMapStringsSep " " (
              p: toString p.providedSessions
            ) nodes.machine.services.displayManager.sessionPackages
          }".split()
          assert "hyprsimple" in sessions, f"login screens are not told about it: {sessions}"
          entry = "/run/current-system/sw/share/wayland-sessions/hyprsimple.desktop"
          machine.succeed(f"grep -qx 'Name=Hyprsimple' {entry}")
          machine.succeed(f"grep -q '^Exec=/nix/store/[^ ]*/bin/uwsm start .*-D Hyprland:Hyprsimple' {entry}")

      with subtest("hyprsimple-install sets the user up"):
          user("mkdir -p /tmp/muslimtify-plugin && cp -r /etc/muslimtify-plugin/. /tmp/muslimtify-plugin/"
               " && chmod -R u+w /tmp/muslimtify-plugin"
               " && git -C /tmp/muslimtify-plugin init -q"
               " && git -C /tmp/muslimtify-plugin add -A"
               " && git -C /tmp/muslimtify-plugin -c user.name=t -c user.email=t@t commit -qm plugin")
          # Configs the user already has: one of their own, and one that looks
          # like Home Manager's (a link into /nix/store).
          user("mkdir -p ~/.config/ghostty && echo 'font-size = 13' > ~/.config/ghostty/config")
          user("ln -s $(readlink -f /etc/hyprsimple/source)/.config/yazi ~/.config/yazi")
          out = user("HYPRSIMPLE_NIX_MUSLIMTIFY_SOURCE=/tmp/muslimtify-plugin hyprsimple-install -y 2>&1")
          print(out)
          assert "hyprsimple is set up for alice" in out, "install reported failures"
          assert "Home Manager" in out, "a config linked into /nix/store was not pointed out"
          user("grep -qx 'font-size = 13' ~/.config/ghostty.backup/config")
          # The home folders a desktop environment would have made.
          user("for d in Desktop Documents Downloads Music Pictures Public Templates Videos; do test -d ~/$d || exit 1; done")
          user("grep -q '^XDG_DOCUMENTS_DIR=' ~/.config/user-dirs.dirs")
          user("test -L ~/.config/yazi.backup && test -d ~/.config/yazi && test ! -L ~/.config/yazi")

          user("test -d ~/.local/share/hyprsimple/.git")
          user("test \"$(git -C ~/.local/share/hyprsimple branch --show-current)\" = nixos")
          user("test -w ~/.local/share/hyprsimple/default/hypr/hyprsimple.lua")
          user("test -L ~/.config/hypr/hyprsimple")
          user("test -x ~/.local/bin/theme-switcher.sh")
          user("head -n1 ~/.local/bin/theme-switcher.sh | grep -qx '#!/usr/bin/env bash'")
          user("test $(ls ~/.local/state/hyprsimple/migrations/*.sh | wc -l) -eq $(ls ~/.local/share/hyprsimple/migrations/*.sh | wc -l)")
          user("grep -q 'source ~/.local/bin/bashrc.sh' ~/.bashrc")
          user("systemctl --user is-enabled hyprpaper.service hyprpolkitagent.service hyprsunset.service"
               " battery-monitor.timer hyprsimple-audio-autoswitch.service")
          user("test -L ~/.config/systemd/user/hyprsunset.service.d/10-hyprsimple.conf")
          # The services NixOS ships run from /etc/systemd/user, which always
          # holds the current system's, not from a link into /nix/store that
          # would keep the version of install day (and break after a garbage
          # collection: no wallpaper, no password prompts).
          for unit in ("hyprpaper", "hyprpolkitagent", "hyprsunset"):
              first = user(f"systemctl --user cat {unit}.service | head -n1")
              assert first.startswith(f"# /etc/systemd/user/{unit}.service"), first
          user("test -z \"$(find ~/.config/systemd/user -maxdepth 2 -type l -lname '/nix/store/*')\"")
          user("systemctl --user is-enabled hyprpaper.service hyprpolkitagent.service hyprsunset.service")
          # hyprsimple's script for the login entry points to the NixOS setting.
          out = user("~/.local/bin/hyprsimple-session.sh")
          assert "programs.hyprsimple.loginEntry.enable = true;" in out, out

      with subtest("the theme switcher reached GTK through dconf"):
          user("gsettings get org.gnome.desktop.interface color-scheme | grep -q prefer-dark")
          user("gsettings get org.gnome.desktop.interface icon-theme | grep -q Yaru")
          user("test -s ~/.config/dconf/user")
          user("test -L ~/.config/hypr/theme-active.lua")

      with subtest("muslimtify is installed as a plugin with a unit that survives upgrades"):
          user("hyprsimple-plugin list | grep -q '^muslimtify'")
          user("grep -Eq '^ExecStart=\"?/run/current-system/sw/bin/muslimtify\"? daemon run$' ~/.config/systemd/user/muslimtify.service")
          # A named time zone gets its real offset, even for a program started
          # without TZDIR (it used to be "UTC+0.0", and prayer times hours off).
          for env in ("", "env -u TZDIR "):
              out = user(f"{env}muslimtify location set --lat=25.40 --long=55.48 --timezone=Asia/Dubai 2>&1")
              assert "Asia/Dubai (UTC+4.0)" in out, out

      with subtest("every command hyprsimple's scripts run is on PATH"):
          commands = """
            amixer awk bash bluetoothctl brightnessctl btop busctl cliphist cmp cpupower curl
            dbus-monitor dbus-update-activation-environment diff dnsmasq fastfetch ffmpeg file
            flock fzf gawk getent getopt ghostty git grim gsettings haveged hostapd hostname
            hyprctl hypridle hyprlock hyprpaper hyprpicker hyprshot hyprshutdown hyprsunset
            inxi ip iptables iw iwconfig iwlist jq lazygit less locale lsd lspci magick md5sum
            muslimtify nautilus nmcli notify-send nvim nwg-look pactl pgrep pidof pkexec pkill
            playerctl powerprofilesctl pw-cli qs realpath rg script setsid sha256sum slurp
            starship sudo swayimg systemctl timeout upower uwsm vi which wf-recorder wl-copy
            wl-mirror wl-paste wl-screenrec wpctl xdg-open yazi zenity zoxide Hyprland
            envsubst fuser gpg htop killall mpv openssl pstree python3 secret-tool
            sensors smartctl update-desktop-database vim wget xdg-terminal-exec xdg-user-dirs-update
          """.split()
          missing = user("for c in " + " ".join(commands) + "; do command -v $c >/dev/null || echo $c; done").split()
          assert not missing, f"not on PATH: {missing}"

      with subtest("hyprsimple-nixos gpu recognises the virtual machine"):
          out = user("hyprsimple-nixos gpu 2>&1")
          print(out)
          assert "virtual machine" in out, out
          assert "You do not need a gpu.nix" in out, out
          user("hyprsimple-nixos gpu --file | grep -q 'Nothing needs setting'")

      with subtest("hyprsimple's Lua config parses with this Hyprland"):
          out = user("Hyprland --verify-config -c ~/.config/hypr/hyprland.lua 2>&1")
          assert "config ok" in out, out

      with subtest("the shells hyprsimple sets up start without warnings"):
          # zoxide warns on the first cd when it is not set up last (upstream's
          # bashrc.sh set it up before starship).
          out = user("TERM=xterm-256color bash -ic 'cd /tmp; cd /' 2>&1")
          assert "zoxide: detected" not in out, out
          for shell, rc in (("zsh", "zsh.sh"), ("fish", "fish.fish")):
              out = user(f"TERM=xterm-256color {shell} -ic 'source ~/.local/bin/{rc}; cd /tmp; cd /' 2>&1")
              assert "zoxide: detected" not in out, f"{shell}: {out}"

      with subtest("files open with the right programs"):
          assert user("xdg-mime query default application/pdf").strip() == "firefox.desktop"
          assert user("xdg-mime query default video/mp4").strip() == "mpv.desktop"
          assert user("xdg-mime query default inode/directory").strip() == "org.gnome.Nautilus.desktop"

      with subtest("the file manager can preview pictures and videos"):
          def exec_of(thumbnailer):
              return user(f"sed -n 's/^Exec=\\([^ ]*\\).*/\\1/p' /run/current-system/sw/share/thumbnailers/{thumbnailer}.thumbnailer").strip()
          user(f"{exec_of('webp-pixbuf')} -s 128 \"$(find ~/.config/hypr/themes -name '*.webp' | head -n1)\" /tmp/webp.png && test -s /tmp/webp.png")
          user(f"{exec_of('gdk-pixbuf-thumbnailer')} -s 128 \"$(find ~/.config/hypr/themes -name '*.jpg' | head -n1)\" /tmp/jpg.png && test -s /tmp/jpg.png")
          user("ffmpeg -nostdin -loglevel error -f lavfi -i testsrc=duration=1:size=320x240:rate=10 /tmp/clip.mp4"
               " && ffmpegthumbnailer -i /tmp/clip.mp4 -o /tmp/clip.png -s 128 && test -s /tmp/clip.png")

      with subtest("a Hyprland session through UWSM"):
          # Leave the home folder the way hyprsimple-nix's first version did
          # (Pictures and Videos only), so the login has to make the rest.
          user("rm -f ~/.config/user-dirs.dirs ~/.config/user-dirs.locale ~/.config/gtk-3.0/bookmarks"
               " && rmdir ~/Desktop ~/Documents ~/Downloads ~/Music ~/Public ~/Templates"
               " && (rmdir ~/Projects 2>/dev/null || true)")
          machine.wait_until_succeeds("pgrep -t tty1 -u alice bash", timeout=60)
          machine.send_chars("uwsm start hyprland-uwsm.desktop\n")
          try:
              machine.wait_until_succeeds("ls /run/user/1000/hypr/*/.socket.sock", timeout=180)
          except Exception:
              machine.screenshot("no-session")
              dump_session()
              raise
          try:
              machine.wait_until_succeeds(
                  "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 monitors' | grep -q Monitor",
                  timeout=120,
              )
          except Exception:
              machine.screenshot("no-monitors")
              dump_session()
              raise
          errors = user("hyprctl configerrors 2>&1")
          print("configerrors:", errors)
          assert errors.strip() in ("", "no errors"), errors

          try:
              machine.wait_until_succeeds(
                  "pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell'",
                  timeout=120,
              )
          except Exception:
              machine.screenshot("no-bar")
              print(machine.execute("ps -eo pid,user,args | grep -iE 'qs|quickshell|hypr' | grep -v grep")[1])
              print(user("journalctl --user -b --no-pager -o short-monotonic | grep -iE 'qs|quickshell|qml' | tail -n 60", check=False)[1])
              print(user("WAYLAND_DISPLAY=$(basename $(ls /run/user/1000/wayland-* | grep -v lock | head -1)) "
                         "QML_IMPORT_PATH=$HOME/.local/share/hyprsimple/default/quickshell "
                         "timeout 20 qs -p ~/.local/share/hyprsimple/default/quickshell 2>&1 | tail -n 80", check=False)[1])
              raise
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 busctl --user status org.freedesktop.Notifications'",
              timeout=60,
          )
          user("systemctl --user is-active graphical-session.target")
          # What Hyprland starts knows where the time zones are.
          user("tr '\\0' '\\n' < /proc/$(pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell' | head -1)/environ"
               " | grep -q '^TZDIR=/'")
          # The login made the home folders, and put them in the file manager's sidebar.
          machine.wait_until_succeeds("su - alice -c 'test -d ~/Documents && test -d ~/Downloads && test -d ~/Music'", timeout=60)
          machine.wait_until_succeeds("su - alice -c 'grep -q /Documents ~/.config/gtk-3.0/bookmarks'", timeout=60)
          # The accessibility bus answers.
          user("busctl --user call org.a11y.Bus /org/a11y/bus org.a11y.Bus GetAddress")
          # A password keyring and the file manager's search index are there to start.
          activatable = user("busctl --user list --activatable")
          for name in ("org.freedesktop.secrets", "org.freedesktop.LocalSearch3"):
              assert name in activatable, f"{name} cannot be started"
          for unit in ("hyprpolkitagent.service", "hyprsunset.service", "battery-monitor.timer",
                       "hyprsimple-audio-autoswitch.service"):
              machine.wait_until_succeeds(
                  f"su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active {unit}'",
                  timeout=60,
              )
          # The session starts hyprpaper. It cannot draw here: without a 3D
          # GPU it gets no GBM buffers and exits, so only the start is checked.
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user show -p ExecMainStartTimestampMonotonic --value hyprpaper.service' | grep -qv '^0$'",
              timeout=60,
          )
          machine.sleep(10)
          machine.screenshot("deep-sea")

      with subtest("everyday things work inside the session"):
          def in_session(cmd):
              return user(f"systemd-run --user --wait --collect --pipe --quiet sh -c {shlex.quote(cmd)} 2>&1")
          # A terminal program from the app menu: the launcher runs `uwsm app -- btop.desktop`.
          def terminals():
              return int(user("hyprctl clients -j | jq '[.[] | select(.class == \"com.mitchellh.ghostty\")] | length'").strip() or 0)
          before = terminals()
          # Detached, as the launcher does it: uwsm app stays in front while the app runs.
          user("setsid -f uwsm app -- btop.desktop >/dev/null 2>&1 </dev/null")
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 clients -j' | jq -e '[.[] | select(.class == \"com.mitchellh.ghostty\")] | length > " + str(before) + "'",
              timeout=60,
          )
          # Copy and paste.
          assert "hello" in in_session("echo hello | wl-copy && sleep 1 && wl-paste")
          # A screenshot, with grim, which hyprsimple's Print key uses. (Its own
          # modes wait for a click to pick a region, window or screen.)
          in_session("grim /tmp/screen.png")
          user("test -s /tmp/screen.png")

      with subtest("switching theme at runtime"):
          kvantum = "~/.config/Kvantum/kvantum.kvconfig"
          # Qt programs go light and dark with the theme, as GTK ones do.
          user("~/.local/bin/theme-switcher.sh catppuccin-latte")
          user(f"grep -qx theme=KvGnome {kvantum}")
          # A Kvantum theme of the user's own stays.
          user(f"sed -i 's/^theme=.*/theme=KvArc/' {kvantum}")
          user("~/.local/bin/theme-switcher.sh tokyo-night-day")
          user(f"grep -qx theme=KvArc {kvantum}")
          user(f"sed -i 's/^theme=.*/theme=KvGnome/' {kvantum}")
          user("~/.local/bin/theme-switcher.sh tokyo-night")
          user(f"grep -qx theme=KvGnomeDark {kvantum}")
          user("readlink ~/.config/hypr/theme-active.lua | grep -q tokyo-night")
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors
          machine.sleep(5)
          machine.screenshot("tokyo-night")

      with subtest("the bar loaded every module and image it asked for"):
          journal = user("journalctl --user -b --no-pager -o cat 2>&1")
          assert "Unsupported image format" not in journal, "Qt could not read an image (webp?)"
          missing_modules = re.findall(r'module "[^"]+" is not installed', journal)
          assert not missing_modules, missing_modules

      with subtest("the settings guide's commands move the prayer time to the right"):
          # Run as written, in the session, the way a terminal there runs them:
          # what they start in the background (the new bar) outlives them.
          guide = open("${../docs/settings.md}").read()
          part = guide.split("**To move the prayer time to the right side of the bar,**")[1]
          block = re.findall(r"```sh\n(.*?)```", part, re.S)[0]
          print(user(f"systemd-run --user --wait --collect --pipe --quiet -p KillMode=process sh -c {shlex.quote(block)} 2>&1"))
          user("jq -e '.plugins.muslimtify.placement == \"right\"' ~/.config/hyprsimple/plugins.json")
          machine.wait_until_succeeds(
              "pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell'",
              timeout=60,
          )
          machine.sleep(5)
          machine.screenshot("prayer-time-right")

      with subtest("workspace names and window groups, turned on by a rebuild"):
          machine.succeed("${nodes.machine.system.build.toplevel}/specialisation/extras/bin/switch-to-configuration test")
          user("hyprctl reload")
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 workspacerules -j' | grep -q '\"defaultName\": \"Term\"'",
              timeout=30,
          )
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors
          binds = user("hyprctl binds -j")
          for key in ("Group Windows / Ungroup", "Take Window out of Group", "Move Window into Group Left",
                      "Next Window in Group", "Window 1 in Group"):
              assert key in binds, f"no key for: {key}"
          machine.sleep(3)
          machine.screenshot("workspace-names")

          def wait_for(jq, expected, workspace=6):
              machine.wait_until_succeeds(
                  "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 clients -j'"
                  f" | jq -e '[.[] | select(.workspace.id == {workspace} and .class == \"com.mitchellh.ghostty\")] | "
                  + jq + " == " + str(expected) + "'",
                  timeout=60,
              )
          def terminal():
              user("setsid -f uwsm app -- ghostty >/dev/null 2>&1 </dev/null")

          # Three terminals as one group, on an empty workspace.
          machine.send_key("meta_l-6")
          terminal()
          wait_for("length", 1)
          machine.send_key("meta_l-g")
          wait_for("map(.grouped | length) | max", 1)
          terminal()
          wait_for("length", 2)
          terminal()
          wait_for("length", 3)
          wait_for("map(.grouped | length) | min", 3)
          machine.sleep(2)
          machine.screenshot("window-group")

          # Out of the group and back in.
          machine.send_key("meta_l-alt-g")
          wait_for("map(.grouped | length) | sort", [0, 2, 2])
          machine.send_key("meta_l-alt-left")
          wait_for("map(.grouped | length) | min", 3)

          # Closing the first window, then any other, closes only that one.
          machine.send_key("meta_l-alt-1")
          first = user("hyprctl activewindow -j | jq -r .address").strip()
          machine.send_key("meta_l-q")
          wait_for("length", 2)
          assert first not in user("hyprctl clients -j"), "the first window is still there"
          wait_for("map(.grouped | length) | min", 2)
          machine.send_key("meta_l-alt-tab")
          machine.send_key("meta_l-q")
          wait_for("length", 1)
          machine.send_key("meta_l-q")
          wait_for("length", 0)
          machine.send_key("meta_l-1")

      with subtest("the i3 layout: tabs, splits, and the key that switches a workspace"):
          machine.wait_until_succeeds("su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 plugin list' | grep -q hy3", timeout=30)
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors
          binds = user("hyprctl binds -j")
          for key in ("Switch This Workspace: Hyprland / i3 Layout", "i3 Layout: Next Window Beside",
                      "i3 Layout: Turn the Split", "Tabs / Split", "Next Tab", "Tab 1"):
              assert key in binds, f"no key for: {key}"

          def placed(workspace):
              return sorted(
                  (tuple(c["at"]), tuple(c["size"]))
                  for c in json.loads(user("hyprctl clients -j"))
                  if c["workspace"]["id"] == workspace and c["class"] == "com.mitchellh.ghostty"
              )
          def eventually(check, what, timeout=30):
              end = time.time() + timeout
              while not check():
                  if time.time() > end:
                      raise AssertionError(what)
                  time.sleep(0.5)
          # The whole screen, but the bar.
          monitor = json.loads(user("hyprctl monitors -j"))[0]
          left, top, right, bottom = monitor["reserved"]
          screen = ((monitor["x"] + left, monitor["y"] + top),
                    (monitor["width"] - left - right, monitor["height"] - top - bottom))
          print("whole screen:", screen)

          # Workspace 2 starts in the i3 layout. One window: no tab bar, no
          # gaps, no border, the whole screen.
          machine.send_key("meta_l-2")
          terminal()
          wait_for("length", 1, workspace=2)
          eventually(lambda: placed(2) == [screen], f"one window is not the whole screen: {placed(2)}")
          # A second window makes tabs: both in the same place, under the tab bar.
          terminal()
          wait_for("length", 2, workspace=2)
          eventually(lambda: len(set(placed(2))) == 1 and placed(2)[0][0][1] > screen[0][1],
                     f"two windows did not become tabs: {placed(2)}")
          machine.sleep(2)
          machine.screenshot("i3-tabs")
          # SUPER + G splits them side by side, and makes tabs again.
          machine.send_key("meta_l-g")
          eventually(lambda: len({p[0][0] for p in placed(2)}) == 2, f"the tabs did not split: {placed(2)}")
          machine.sleep(1)
          machine.screenshot("i3-split")
          machine.send_key("meta_l-g")
          eventually(lambda: len(set(placed(2))) == 1, f"the split did not become tabs again: {placed(2)}")
          # Closing one leaves the other, as the whole screen again.
          machine.send_key("meta_l-q")
          wait_for("length", 1, workspace=2)
          eventually(lambda: placed(2) == [screen], f"the last window does not fill the screen: {placed(2)}")
          # SUPER + CTRL + SPACE: Hyprland's layout, with its gaps, and back.
          machine.send_key("meta_l-ctrl-spc")
          eventually(lambda: placed(2)[0][0][0] > screen[0][0], f"no switch to Hyprland's layout: {placed(2)}")
          machine.send_key("meta_l-ctrl-spc")
          eventually(lambda: placed(2) == [screen], f"no switch back to the i3 layout: {placed(2)}")
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=2)

          # Workspace 7 starts in Hyprland's layout. Switched, it keeps the i3
          # layout when Hyprland reloads its configuration.
          machine.send_key("meta_l-7")
          machine.send_key("meta_l-ctrl-spc")
          user("hyprctl reload")
          machine.sleep(3)
          terminal()
          wait_for("length", 1, workspace=7)
          terminal()
          wait_for("length", 2, workspace=7)
          eventually(lambda: len(set(placed(7))) == 1, f"workspace 7 lost the i3 layout on reload: {placed(7)}")
          machine.send_key("meta_l-q")
          wait_for("length", 1, workspace=7)
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=7)
          machine.send_key("meta_l-1")

      with subtest("an app opens on its own workspace"):
          # mpv belongs on workspace 8. Started from workspace 1, it opens there.
          user("setsid -f uwsm app -- mpv --idle=yes --force-window=yes >/dev/null 2>&1 </dev/null")
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 clients -j'"
              " | jq -e '[.[] | select(.class == \"mpv\")] | .[0].workspace.id == 8'",
              timeout=60,
          )
          user("pkill -x mpv || true")
          machine.send_key("meta_l-1")
          # A workspace with a window shows it on the bar, from another one.
          machine.send_key("meta_l-3")
          terminal()
          wait_for("length", 1, workspace=3)
          machine.send_key("meta_l-1")
          machine.sleep(2)
          machine.screenshot("bar-workspace-with-windows")
          machine.send_key("meta_l-3")
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=3)
          machine.send_key("meta_l-1")

      with subtest("keys for workspaces 11 and 12, and the number pad"):
          def active():
              return json.loads(user("hyprctl activeworkspace -j"))["id"]
          def press(keys, workspace):
              machine.send_key(keys)
              eventually(lambda: active() == workspace, f"{keys} did not go to workspace {workspace}, but {active()}")
          def existing():
              return sorted(w["id"] for w in json.loads(user("hyprctl workspaces -j")) if w["id"] > 0)
          def window():
              return json.loads(user("hyprctl activewindow -j"))

          press("meta_l-minus", 11)
          press("meta_l-equal", 12)
          terminal()
          wait_for("length", 1, workspace=12)
          press("meta_l-shift-minus", 11)
          wait_for("length", 1, workspace=11)

          # SHIFT + a number goes to that workspace, 5 and 0 back again.
          press("shift-kp_3", 3)
          terminal()
          wait_for("length", 1, workspace=3)
          press("kp_5", 11)
          press("shift-kp_0", 10)
          press("kp_0", 11)
          # 8 and 2: the first and the last workspace there is.
          press("kp_8", existing()[0])
          press("kp_2", existing()[-1])
          # 4 and 6: the workspace before and after.
          here = active()
          before = max(i for i in existing() if i < here)
          press("kp_4", before)
          press("kp_6", here)

          # 7 and 9 move the window, 1 and 3 the focus.
          terminal()
          wait_for("length", 2, workspace=11)
          new = window()
          machine.send_key("kp_7")
          eventually(lambda: window()["at"][0] < new["at"][0], "7 did not move the window left")
          machine.send_key("kp_3")
          eventually(lambda: window()["address"] != new["address"], "3 did not move the focus right")
          machine.send_key("meta_l-q")
          wait_for("length", 1, workspace=11)
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=11)
          press("shift-kp_3", 3)
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=3)
          press("shift-kp_1", 1)

      with subtest("Viewnior zooms with a touchpad on Wayland, a wheel click is one step, and a zoomed photo drags"):
          found = user("readlink -f $(command -v viewnior)").strip()
          assert found != "${pkgs.viewnior}/bin/viewnior", "the unmended Viewnior comes first on PATH"
          user("ffmpeg -nostdin -loglevel error -y -f lavfi -i testsrc=size=640x480 -frames:v 1 /tmp/picture.png")
          def zoom():
              title = user("hyprctl clients -j | jq -r '.[] | select(.class == \"viewnior\") | .title'").strip()
              return int(title.rsplit(" - ", 1)[-1].rstrip("%")) if title else None
          def viewnior():
              user("systemd-run --user --unit=viewnior-test --collect viewnior /tmp/picture.png")
              eventually(lambda: zoom() is not None, "no Viewnior window")
              # The pointer in the middle of the screen, over the photo: the
              # keys of the tests before moved it about.
              user("hyprctl dispatch 'hl.dsp.cursor.move({ x = 640, y = 400 })'")
              machine.sleep(2)
              return zoom()
          def pad(args):
              machine.succeed("${python}/bin/python3 ${./pad.py} " + args)

          # Alone on a workspace, Viewnior fills the screen, under the pointer.
          # A wheel first: Hyprland 0.55 lost the very first scroll of a
          # touchpad plugged in mid-session (a real one is there from boot).
          press("meta_l-9", 9)
          start = viewnior()
          pad("wheel 1")
          eventually(lambda: abs(zoom() - start * 1.1) <= 1,
                     f"one wheel click is not one step: {start}% -> {zoom()}%, pointer at {user('hyprctl cursorpos').strip()}")

          start = zoom()
          pad("fingers 2 0 -120")
          eventually(lambda: zoom() != start, f"two fingers did not zoom: {start}% -> {zoom()}%")

          # Zoomed in further, the photo moves when it is dragged.
          pad("wheel 20")
          eventually(lambda: zoom() > 200, f"not zoomed in: {zoom()}%")
          def photo_area():
              return user("WAYLAND_DISPLAY=$(basename $(ls -d /run/user/1000/wayland-[0-9] | head -1))"
                          " grim -g '200,200 400x300' - | md5sum").split()[0]
          before = photo_area()
          pad("drag -200 -120")
          eventually(lambda: photo_area() != before, "a dragged photo did not move")
          machine.screenshot("viewnior-zoomed")
          user("systemctl --user stop viewnior-test")
          press("meta_l-1", 1)

      with subtest("swayimg and imv answer to Viewnior's keys"):
          user("mkdir -p /tmp/photos"
               " && ffmpeg -nostdin -loglevel error -y -f lavfi -i testsrc=size=640x480 -frames:v 1 /tmp/photos/a.png"
               " && ffmpeg -nostdin -loglevel error -y -f lavfi -i smptebars=size=640x480 -frames:v 1 /tmp/photos/b.png")
          def title(app):
              return user(f"hyprctl clients -j | jq -r '.[] | select(.class == \"{app}\") | .title'").strip()
          press("meta_l-9", 9)
          for app, command in (("swayimg", "swayimg /tmp/photos/a.png"), ("imv", "imv-dir /tmp/photos/a.png")):
              user(f"systemd-run --user --unit=photos --collect {command}")
              eventually(lambda: "a.png" in title(app), f"{app} did not show a.png")
              # The other photo in the folder came along: the keys go to it and back.
              for keys, photo in (("spc", "b.png"), ("backspace", "a.png"), ("end", "b.png"), ("home", "a.png")):
                  machine.send_key(keys)
                  # Once, on 26.05, imv let an End go by and stayed on a.png,
                  # with nothing in its log. So a key that changed nothing in
                  # 10 seconds is pressed once more. A key that is not bound
                  # still fails.
                  try:
                      eventually(lambda: photo in title(app), "", timeout=10)
                  except AssertionError:
                      print(f"{keys} in {app}: nothing after 10 seconds, pressing it again")
                      machine.send_key(keys)
                      eventually(lambda: photo in title(app), f"{keys} in {app} did not show {photo}: {title(app)}")
              before = photo_area()
              machine.send_key("ctrl-r")
              eventually(lambda: photo_area() != before, f"ctrl-r did not turn the photo in {app}")
              machine.send_key("esc")
              eventually(lambda: title(app) == "", f"esc did not close {app}")
          press("meta_l-1", 1)

      # A page of shortcuts lists exactly the keys Hyprland has: every key on
      # it is bound, and every bound key is on it.
      def shortcuts_match(path):
          page = open(path).read()
          held = {"SUPER": 64, "CTRL": 4, "ALT": 8, "SHIFT": 1}
          names = {"→": "right", "←": "left", "↑": "up", "↓": "down", "ESC": "escape", "/": "slash",
                   "ENTER": "return",
                   "left button, drag": "mouse:272", "right button, drag": "mouse:273",
                   "wheel down": "mouse_down", "wheel up": "mouse_up",
                   "Mouse back button": "mouse:275", "Mouse forward button": "mouse:276",
                   "Volume Up key": "XF86AudioRaiseVolume", "Volume Down key": "XF86AudioLowerVolume",
                   "Mute key": "XF86AudioMute", "Microphone Mute key": "XF86AudioMicMute",
                   "Play key": "XF86AudioPlay", "Pause key": "XF86AudioPause",
                   "Next key": "XF86AudioNext", "Previous key": "XF86AudioPrev",
                   "Brightness Up key": "XF86MonBrightnessUp", "Brightness Down key": "XF86MonBrightnessDown",
                   "Keyboard Light Up key": "XF86KbdBrightnessUp", "Keyboard Light Down key": "XF86KbdBrightnessDown"}
          codes = {"-": 20, "=": 21, "Numpad 0": 90, "Numpad 1": 87, "Numpad 2": 88, "Numpad 3": 89,
                   "Numpad 4": 83, "Numpad 5": 84, "Numpad 6": 85, "Numpad 7": 79, "Numpad 8": 80, "Numpad 9": 81,
                   "Numpad .": 91}
          documented = set()
          for part in page.split("\n## ")[1:]:
              # The corners, the bar, the touchpad and the photo viewers are not Hyprland's keys.
              if part.split("\n", 1)[0] in ("Hot corners", "The mouse on the bar", "The touchpad", "Photo viewers"):
                  continue
              for keys in re.findall(r"^\| \*\*(.+?)\*\* \|", part, re.M):
                  *mods, last = keys.split(" + ")
                  mask = sum(held[mod] for mod in mods)
                  if last in codes:
                      documented.add((mask, "", codes[last]))
                  else:
                      documented.add((mask, names.get(last, last).lower(), 0))
          bound = [(b["modmask"], "" if b["keycode"] else b["key"].lower(), b["keycode"])
                   for b in json.loads(user("hyprctl binds -j"))]
          # NixOS 26.05's Hyprland lists a key named by its place (code:) with
          # neither its name nor its code. Those keys are counted instead, for
          # each set of held keys.
          import collections
          unnamed = collections.Counter(mask for mask, key, code in bound if not key and not code)
          if unnamed:
              by_place = collections.Counter(mask for mask, key, code in documented if code)
              assert unnamed == by_place, f"{path}: keys by place: bound {dict(unnamed)}, on the page {dict(by_place)}"
              documented = {entry for entry in documented if not entry[2]}
          named = {entry for entry in bound if entry[1] or entry[2]}
          assert documented == named, (f"{path}: bound, but not on the page: {sorted(named - documented)}; "
                                       f"on the page, but not bound: {sorted(documented - named)}")

      with subtest("Every shortcut (docs/shortcuts.md) lists the keys there are, and only those"):
          shortcuts_match("${../docs/shortcuts.md}")

      with subtest("the keys guide's examples load, and its swipe changes the workspace"):
          guide = open("${../docs/keys.md}").read()
          lua = "\n".join(re.findall(r"```lua\n(.*?)```", guide, re.S))
          # And every action in its table, on keys of their own.
          actions = re.findall(r"`(hl\.dsp\.[^`]+)`", guide)
          for number, action in enumerate(actions, 1):
              lua += f'\nhl.bind("SUPER + CTRL + ALT + SHIFT + code:{number + 9}", {action}, {{ description = "guide action {number}" }})'
          lua += '\nhl.bind("SUPER + CTRL + ALT + SHIFT + F12", hl.dsp.no_op(), { description = "the keys guide loaded" })\n'
          config = "/home/alice/.config/hypr/input.lua"
          machine.succeed(f"cp {config} /tmp/input.lua.saved")
          machine.succeed(f"cat >> {config} <<'GUIDE'\n{lua}\nGUIDE")
          user("hyprctl reload")
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors
          binds = user("hyprctl binds -j")
          for name in ("the keys guide loaded", "Notes", "Workspace Before", "Close Window", f"guide action {len(actions)}"):
              assert name in binds, f"not bound: {name}"
          for option, value in (("input:touchpad:tap-to-click", 1), ("input:accel_profile", "flat")):
              got = json.loads(user(f"hyprctl getoption {option} -j"))
              assert value in got.values(), f"{option}: {got}"

          here = active()
          pad("fingers 3 -400 0")
          eventually(lambda: active() != here, "a 3-finger swipe did not change the workspace")
          pad("fingers 3 400 0")
          eventually(lambda: active() == here, "a 3-finger swipe back did not come back")

          machine.succeed(f"cp /tmp/input.lua.saved {config}")
          user("hyprctl reload")

      with subtest("mysh264's setup: its keys, a key of your own, its lines, the drop-down terminal, hot corners"):
          machine.succeed("${nodes.machine.system.build.toplevel}/specialisation/mysh264/bin/switch-to-configuration test")
          user("hyprctl reload")
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 binds -j' | grep -q 'Screenshot of the Window'",
              timeout=30,
          )
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors
          # Every key of the setup is on its page, and nothing else.
          shortcuts_match("${../docs/shortcuts-mysh264.md}")

          def bound(mods, key):
              return [b["description"] for b in json.loads(user("hyprctl binds -j"))
                      if b["modmask"] == mods and b["key"].lower() == key]
          # hyprsimple's own applications.lua binds SUPER + A and SUPER + M;
          # the setting gives those keys other jobs, and only those.
          assert bound(64, "a") == ["Switch This Workspace: Hyprland / i3 Layout"], bound(64, "a")
          assert bound(64, "m") == ["Toggle Bar"], bound(64, "m")
          assert bound(64, "d") == ["App Launcher"], bound(64, "d")

          # SUPER + A switches the layout, through hyprsimple_nix.jobs, and back.
          state = "/run/user/1000/hyprsimple-nix-i3-workspaces"
          def layout_of(workspace):
              lines = machine.succeed(f"cat {state} 2>/dev/null || true").splitlines()
              if f"{workspace} i3" in lines:
                  return "i3"
              return "hyprland"
          if active() == 5:
              press("meta_l-6", 6)
          press("meta_l-5", 5)
          machine.send_key("meta_l-a")
          eventually(lambda: layout_of(5) == "i3", "SUPER + A did not switch workspace 5 to the i3 layout")
          machine.send_key("meta_l-a")
          eventually(lambda: layout_of(5) == "hyprland", "SUPER + A did not switch workspace 5 back")
          # SUPER + the workspace you are on goes back to the one before.
          press("meta_l-4", 4)
          press("meta_l-3", 3)
          press("meta_l-3", 4)
          # SUPER + TAB: the next workspace there is, and after the last, the first.
          ids = sorted(w["id"] for w in json.loads(user("hyprctl workspaces -j")) if w["id"] > 0)
          after = ids[(ids.index(active()) + 1) % len(ids)]
          press("meta_l-tab", after)
          # SUPER + SHIFT + S hides a window in the scratchpad, SUPER + S shows
          # it, and SUPER + SHIFT + S again takes it back out.
          # Where a window is: its workspace's name and number. (Workspace 9
          # is called Game in this setup. Hyprland 0.57 gives a window in the
          # scratchpad no workspace number.)
          def place(address):
              for client in json.loads(user("hyprctl clients -j")):
                  if client["address"] == address:
                      return client["workspace"].get("name"), client["workspace"].get("id")
          def shown():
              return json.loads(user("hyprctl monitors -j"))[0]["specialWorkspace"]["name"]
          press("meta_l-9", 9)
          terminal()
          wait_for("length", 1, workspace=9)
          address = json.loads(user("hyprctl activewindow -j"))["address"]
          machine.send_key("meta_l-shift-s")
          eventually(lambda: place(address)[0] == "special:magic", f"SUPER + SHIFT + S left the window on {place(address)}")
          assert shown() == "", "the scratchpad came up with the window"
          machine.send_key("meta_l-s")
          eventually(lambda: shown() == "special:magic", "SUPER + S did not show the scratchpad")
          machine.send_key("meta_l-shift-s")
          eventually(lambda: place(address)[1] == 9 or place(address)[0] in ("9", "Game"),
                     f"SUPER + SHIFT + S left the window on {place(address)}")
          eventually(lambda: shown() == "", "the empty scratchpad stayed on the screen")
          machine.send_key("meta_l-q")
          wait_for("length", 0, workspace=9)

          # A key of your own wins over the setting's: SUPER + D is yours alone.
          # And a line of yours for SUPER + M, word for word like hyprsimple's
          # (which comes first in the file and is left out), wins too.
          apps = "/home/alice/.config/hypr/bindings/applications.lua"
          machine.succeed(f"cp {apps} /tmp/applications.lua.saved")
          machine.succeed(f"cat >> {apps} <<'MINE'\n"
                          'hl.bind("SUPER + D", hl.dsp.exec_cmd("true"), { description = "Mine" })\n'
                          'hl.bind("SUPER + M", hl.dsp.exec_cmd("sh -c \'hyprpicker | wl-copy\'"), { description = "Color Picker" })\n'
                          "MINE")
          user("hyprctl reload")
          eventually(lambda: bound(64, "d") == ["Mine"], f"SUPER + D: {bound(64, 'd')}")
          assert bound(64, "m") == ["Color Picker"], bound(64, "m")
          assert bound(64, "a") == ["Switch This Workspace: Hyprland / i3 Layout"], bound(64, "a")
          machine.succeed(f"cp /tmp/applications.lua.saved {apps}")
          user("hyprctl reload")
          eventually(lambda: bound(64, "m") == ["Toggle Bar"], f"SUPER + M after the reload: {bound(64, 'm')}")

          # Its own lines (extraConfig): 3-pixel borders.
          border = json.loads(user("hyprctl getoption general:border_size -j"))
          assert 3 in border.values(), f"general:border_size: {border}"

          # The drop-down terminal, on the number pad's dot. It needs Ghostty
          # 1.4 (ghostty +toggle-quick-terminal), which NixOS 26.05 has not.
          def layer(namespace):
              for monitor in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor["levels"].values():
                      for found in layers:
                          if found["namespace"] == namespace:
                              return found
          if ${if lib.versionAtLeast pkgs.ghostty.version "1.4" then "True" else "False"}:
              machine.send_key("kp_decimal")
              eventually(lambda: layer("ghostty-quick-terminal") is not None, "the drop-down terminal did not come down", timeout=60)
              machine.sleep(2)
              machine.screenshot("dropdown-terminal")
              machine.send_key("kp_decimal")
              eventually(lambda: layer("ghostty-quick-terminal") is None, "the drop-down terminal did not go away")

          # Hot corners. The pointer goes into a corner, and back to the middle.
          monitor = json.loads(user("hyprctl monitors -j"))[0]
          width = round(monitor["width"] / monitor["scale"])
          height = round(monitor["height"] / monitor["scale"])
          def pointer(x, y):
              user(f"hyprctl dispatch 'hl.dsp.cursor.move({{ x = {x}, y = {y} }})'")
          def middle():
              pointer(width // 2, height // 2)
              machine.sleep(1)
          # The bar: its layer spans the screen (a notification's is narrow).
          def full_bar():
              for monitor_layers in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor_layers["levels"].values():
                      for candidate in layers:
                          if candidate["namespace"] == "quickshell" and candidate["w"] > width // 2:
                              return candidate
          middle()
          assert full_bar() is not None, "no bar before the corners"
          # Top left: the bar hides, and the same corner shows it again.
          pointer(0, 0)
          eventually(lambda: full_bar() is None, "the top left corner did not hide the bar")
          middle()
          pointer(0, 0)
          eventually(lambda: full_bar() is not None, "the top left corner did not show the bar again")
          middle()
          # Top right: the desktop, an empty workspace, and there again, back.
          press("meta_l-2", 2)
          pointer(width - 1, 0)
          eventually(lambda: active() == 97, f"the top right corner went to {active()}, not to the desktop")
          middle()
          pointer(width - 1, 0)
          eventually(lambda: active() == 2, f"the top right corner went to {active()}, not back to 2")
          middle()
          # Bottom right: back to the workspace before.
          press("meta_l-4", 4)
          pointer(width - 1, height - 1)
          eventually(lambda: active() == 2, f"the bottom right corner went to {active()}, not back to 2")
          middle()

          # The prayer time's place, from the NixOS configuration: an update
          # puts it back on the right.
          user("f=~/.config/hyprsimple/plugins.json && jq '.plugins.muslimtify.placement = \"left\"' \"$f\" > \"$f.new\" && mv \"$f.new\" \"$f\"")
          out = user("hyprsimple-update 2>&1")
          print(out)
          assert "The prayer time is now on the right of the bar" in out, "the update did not move the prayer time"
          user("jq -e '.plugins.muslimtify.placement == \"right\"' ~/.config/hyprsimple/plugins.json")
          press("meta_l-1", 1)

      with subtest("after logging out and in, the bar is at the bottom with even workspaces, opens upwards, and comes back at the edge"):
          machine.succeed("grep -Eq 'HYPRSIMPLE_BAR +DEFAULT=\"bottom\"' /etc/pam/environment")
          machine.succeed("grep -Eq 'HYPRSIMPLE_BAR_WORKSPACE_WIDTH +DEFAULT=\"65\"' /etc/pam/environment")
          machine.succeed("grep -Eq 'HYPRSIMPLE_BAR_PEEK +DEFAULT=\"1\"' /etc/pam/environment")
          machine.succeed("grep -Eq 'HYPRSIMPLE_BAR_PEEK_INSET +DEFAULT=\"8\"' /etc/pam/environment")
          # This session began before the rebuild that brought the settings, as
          # a user's does. The guide says to log out and back in, so this does:
          # out of Hyprland, and out of tty1 too, so that the automatic login
          # makes a new login. That login has to bring the settings to the bar
          # by itself, while systemd's user manager, still running from the
          # first login, does not have them.
          machine.wait_until_succeeds("su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 uwsm stop'", timeout=60)
          machine.wait_until_fails("pgrep -u alice -f 'Hyprland --watchdog-fd'", timeout=60)
          machine.succeed("rm -rf /run/user/1000/hypr")
          first_login = machine.succeed("pgrep -o -t tty1 -u alice bash").strip()
          machine.send_chars("exit\n")
          machine.wait_until_succeeds(f"p=$(pgrep -o -t tty1 -u alice bash) && [ \"$p\" != {first_login} ]", timeout=60)
          machine.send_chars("uwsm start hyprland-uwsm.desktop\n")
          bar_command = "qs -p /home/alice/.local/share/hyprsimple/default/quickshell"
          try:
              machine.wait_until_succeeds("ls /run/user/1000/hypr/*/.socket.sock", timeout=180)
              machine.wait_until_succeeds(f"pgrep -u alice -f '{bar_command}'", timeout=120)
          except Exception:
              machine.screenshot("no-session-after-login")
              dump_session()
              raise
          bar = machine.succeed(f"pgrep -o -u alice -f '{bar_command}'").strip()
          bar_env = machine.succeed(f"tr '\\0' '\\n' < /proc/{bar}/environ").split("\n")
          print("the bar's settings:", [v for v in bar_env if v.startswith("HYPRSIMPLE_")])
          for setting in ("HYPRSIMPLE_BAR=bottom", "HYPRSIMPLE_BAR_WORKSPACE_WIDTH=65",
                          "HYPRSIMPLE_BAR_PEEK=1", "HYPRSIMPLE_BAR_PEEK_INSET=8"):
              assert setting in bar_env, f"the new login did not bring {setting} to the bar"
          def bar_layer():
              for monitor in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor["levels"].values():
                      for layer in layers:
                          if layer["namespace"] == "quickshell":
                              return layer
          monitor = json.loads(user("hyprctl monitors -j"))[0]
          eventually(lambda: (bar_layer() or {}).get("y", 0) > 0 and bar_layer()["y"] + bar_layer()["h"] == monitor["height"],
                     f"the bar is not at the bottom: {bar_layer()}")
          # mysh264's setup starts the Conky panel with the session, from the
          # user's own copy, which can be changed, with its font in place.
          eventually(lambda: machine.execute("pgrep -u alice -x conky")[0] == 0, "Conky did not start", timeout=60)
          user("test -w ~/.config/lean-conky-config/conky.conf && test -f ~/.config/lean-conky-config/local.conf.example")
          user("test -L ~/.local/share/fonts/lean-conky-config.otf && test -e ~/.local/share/fonts/lean-conky-config.otf")
          def conky_layer():
              for monitor_layers in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor_layers["levels"].values():
                      for found in layers:
                          # "conky" from Conky 1.25 on, "conky_namespace" before.
                          if found["namespace"] in ("conky", "conky_namespace"):
                              return found
          try:
              eventually(lambda: conky_layer() is not None, "the Conky panel is not on the screen", timeout=60)
          except Exception:
              print(user("journalctl --user -b --no-pager | grep -iE 'conky|lcc' | tail -n 40", check=False)[1])
              raise
          print("the Conky panel:", conky_layer())
          machine.sleep(3)
          machine.screenshot("bar-after-login")

          # The hidden bar comes back at the bottom edge, over the windows,
          # which keep the whole screen, and goes again when the pointer
          # leaves it. The edge leaves its two ends to the hot corners.
          def wide_bar():
              for monitor_layers in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor_layers["levels"].values():
                      for found in layers:
                          if found["namespace"] == "quickshell" and found["w"] > monitor["width"] // 2:
                              return found
          def peek_edge():
              for monitor_layers in json.loads(user("hyprctl layers -j")).values():
                  for layers in monitor_layers["levels"].values():
                      for found in layers:
                          if found["namespace"] == "quickshell-peek":
                              return found
          def room_below():
              return json.loads(user("hyprctl monitors -j"))[0]["reserved"][3]
          def pointer(x, y):
              user(f"hyprctl dispatch 'hl.dsp.cursor.move({{ x = {x}, y = {y} }})'")
          visible = "qs -p ~/.local/share/hyprsimple/default/quickshell ipc call bar toggleVisible"
          middle_x, bottom = monitor["width"] // 2, monitor["height"] - 1
          pointer(middle_x, monitor["height"] // 2)
          assert peek_edge() is None, "the edge is there while the bar is shown"
          in_session(visible)
          eventually(lambda: wide_bar() is None and room_below() == 0, "the bar did not hide")
          eventually(lambda: peek_edge() is not None, "no edge to bring the hidden bar back")
          edge = peek_edge()
          assert edge["y"] + edge["h"] == monitor["height"] and edge["h"] == 2, f"the edge is not along the bottom: {edge}"
          assert edge["x"] == 8 and edge["w"] == monitor["width"] - 16, f"the edge does not leave its ends to the hot corners: {edge}"
          pointer(middle_x, bottom)
          eventually(lambda: wide_bar() is not None, "the pointer at the edge did not bring the bar back")
          assert room_below() == 0, "the bar came back taking room from the windows"
          machine.screenshot("bar-peek")
          pointer(middle_x, monitor["height"] // 2)
          eventually(lambda: wide_bar() is None, "the bar did not go when the pointer left it")
          # Touched and left at once, without going onto the bar.
          pointer(middle_x, bottom)
          pointer(middle_x, monitor["height"] // 2)
          eventually(lambda: wide_bar() is None and peek_edge() is not None, "the bar stayed after the edge was only touched")
          in_session(visible)
          eventually(lambda: wide_bar() is not None and room_below() == 36, "the bar did not come back for good")
          assert peek_edge() is None, "the edge stayed with the bar shown"
          panel = "qs -p ~/.local/share/hyprsimple/default/quickshell ipc call bar toggle "
          in_session(panel + "calendar")
          machine.sleep(2)
          machine.screenshot("bar-bottom-panel")
          in_session(panel + "calendar")
          in_session("notify-send 'hyprsimple-nix' 'The bar is at the bottom'")
          machine.sleep(2)
          machine.screenshot("bar-bottom-notification")

      with subtest("hyprsimple-update with nothing new"):
          # An install from before the fix: hyprpaper's unit linked from
          # /nix/store, as `systemctl --user enable` leaves it. The update
          # points it back at the system's.
          user("ln -sfn \"$(readlink -f /etc/systemd/user/hyprpaper.service)\" ~/.config/systemd/user/hyprpaper.service"
               " && ln -sfn \"$(readlink -f /etc/systemd/user/hyprpaper.service)\" ~/.config/systemd/user/graphical-session.target.wants/hyprpaper.service"
               " && systemctl --user daemon-reload")
          out = user("hyprsimple-update 2>&1")
          print(out)
          assert "already what your NixOS configuration provides" in out
          assert "hyprsimple is up to date" in out
          assert "Now from your current system: hyprpaper.service" in out, "the pinned unit was not repaired"
          user("test -z \"$(find ~/.config/systemd/user -maxdepth 2 -type l -lname '/nix/store/*')\"")
          assert user("systemctl --user cat hyprpaper.service | head -n1").startswith("# /etc/systemd/user/hyprpaper.service")
          user("systemctl --user is-enabled hyprpaper.service")

      with subtest("hyprsimple-update after an upgrade brings a new version"):
          # Stand in for a rebuild that brings a new hyprsimple: a copy of the
          # tree with a new version number, a changed config, a changed bar,
          # a new migration that asks pacman, and a package hyprsimple-nix does
          # not know about yet.
          machine.succeed(
              "cp -r $(readlink -f /etc/hyprsimple/source) /tmp/next && chmod -R u+w /tmp/next"
              " && echo 9.9.9 > /tmp/next/version"
              " && echo '# changed upstream' >> /tmp/next/.config/starship.toml"
              " && echo '// changed upstream' >> /tmp/next/default/quickshell/shell.qml"
              " && echo 'some-new-package' >> /tmp/next/packages.txt"
              " && printf 'pacman -Qi hyprland >/dev/null && touch \"$HOME/migration-ran\"\\n' > /tmp/next/migrations/9999999999.sh"
              " && ln -sfn /tmp/next /etc/hyprsimple/source"
          )
          user("echo '# mine' >> ~/.config/starship.toml")
          out = user("hyprsimple-update 2>&1")
          print(out)
          assert "${nodes.machine.programs.hyprsimple.package.version} -> 9.9.9" in out, "sync did not report the version change"
          assert "some-new-package" in out, "the unknown package was not reported"
          assert "hyprsimple-refresh-config.sh starship.toml" in out, "the changed config was not reported"
          assert "The bar changed" in out, "the bar was not restarted"
          user("test -f ~/migration-ran")
          user("test -f ~/.local/state/hyprsimple/migrations/9999999999.sh")
          user("test \"$(git -C ~/.local/share/hyprsimple rev-list --count HEAD)\" = 2")
          user("test \"$(cat ~/.local/share/hyprsimple/version)\" = 9.9.9")
          try:
              machine.wait_until_succeeds(
                  "pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell'",
                  timeout=60,
              )
          except Exception:
              dump_session()
              raise

      with subtest("the Hyprsimple login entry starts the same desktop"):
          # Retried: when a timer (battery-monitor) queues a start at that very
          # moment, systemd refuses the stop as "destructive" and uwsm gives up.
          machine.wait_until_succeeds(
              "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 uwsm stop'",
              timeout=60,
          )
          machine.wait_until_fails("pgrep -u alice -f 'Hyprland --watchdog-fd'", timeout=60)
          machine.succeed("rm -rf /run/user/1000/hypr")
          machine.wait_until_succeeds("pgrep -t tty1 -u alice bash", timeout=60)
          # What a login screen runs for it, and what a text login types.
          machine.send_chars("uwsm start hyprsimple.desktop\n")
          try:
              machine.wait_until_succeeds("ls /run/user/1000/hypr/*/.socket.sock", timeout=180)
              machine.wait_until_succeeds(
                  "pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell'",
                  timeout=120,
              )
          except Exception:
              machine.screenshot("no-hyprsimple-session")
              dump_session()
              raise
          user("systemctl --user show-environment | grep -qx 'XDG_CURRENT_DESKTOP=Hyprland:Hyprsimple'")
          # hyprsimple turns Hyprland's warning about that name off for it.
          option = user("hyprctl getoption misc:disable_xdg_env_checks")
          print("misc:disable_xdg_env_checks:", option)
          assert re.search(r"(int: 1|bool: true)", option), "the XDG warning is on"
          errors = user("hyprctl configerrors 2>&1")
          assert errors.strip() in ("", "no errors"), errors

      with subtest("the removal guide's commands work as written"):
          # Run Part 1 of docs/uninstall.md exactly as a reader would. The
          # remover asks first and wants a terminal for that: script gives it
          # one, and the reader's yes.
          guide = open("${../docs/uninstall.md}").read()
          part1 = guide.split("## Part 1")[1].split("## Part 2")[0]
          blocks = re.findall(r"```sh\n(.*?)```", part1, re.S)
          assert blocks == ["hyprsimple-uninstall.sh\n", "uwsm stop\n"], f"Part 1 runs other commands now: {blocks}"
          out = user("printf 'yes\\n' | script -qec hyprsimple-uninstall.sh /dev/null 2>&1", check=False)[1]
          print(out)
          assert "Done. Log out now" in out, "the remover did not finish"
          # muslimtify, removed with the plugin, names the NixOS setting.
          assert "sudo ./uninstall.sh" not in out, "muslimtify still points to an uninstall.sh"
          assert "programs.hyprsimple.muslimtify.enable = false" in out, "muslimtify did not name the NixOS setting"
          assert "come from your NixOS configuration" in out and "uninstall.md#part-2-for-the-computer" in out, \
              "the remover did not send the reader to Part 2 for the NixOS configuration"
          print(user("uwsm stop 2>&1", check=False)[1])
          # The checkout held nothing of the user's: it is gone, not moved away.
          user("test ! -e ~/.local/share/hyprsimple.hyprsimple-removed")
          user("test ! -e ~/.local/bin/hyprsimple-uninstall.sh")
          # The user's own settings are back where they were.
          user("grep -qx 'font-size = 13' ~/.config/ghostty/config")
          user("test -L ~/.config/yazi && test ! -e ~/.config/yazi.backup")
          # hyprsimple's are put aside, not deleted.
          user("test ! -e ~/.config/hypr && test -d ~/.config/hypr.hyprsimple-removed")
          # Its own files, scripts, services and shell line are gone.
          user("test ! -e ~/.local/share/hyprsimple && test ! -e ~/.local/state/hyprsimple")
          user("test ! -e ~/.local/bin/theme-switcher.sh && test ! -e ~/.local/bin/hyprsimple-plugin")
          user("test ! -e ~/.config/systemd/user/battery-monitor.timer")
          user("! grep -q hyprsimple ~/.bashrc")
          user("! systemctl --user is-enabled hyprpaper.service")
    '';
}
