# End to end: a NixOS machine with the module, a user who runs
# hyprsimple-install, a real Hyprland session started through UWSM, and an
# update to a changed hyprsimple version.
{ pkgs, self }:
let
  # The muslimtify plugin, so its install can run without network access.
  muslimtifyPlugin = pkgs.fetchFromGitHub {
    owner = "muslimtify-org";
    repo = "muslimtify-hyprsimple";
    rev = "0b3920f9f97860fd04ca4db1497ab163f7c20bc4";
    hash = "sha256-HFj/f17B6c+g6rHNUU4owW27a7eUsDcw3sCcT0X803Y=";
  };
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
      import re
      import shlex

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

      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("user@1000.service")

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
          user("ffmpeg -loglevel error -f lavfi -i testsrc=duration=1:size=320x240:rate=10 /tmp/clip.mp4"
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
          user("~/.local/bin/theme-switcher.sh tokyo-night")
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

          def wait_for(jq, expected):
              machine.wait_until_succeeds(
                  "su - alice -c 'XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 clients -j'"
                  " | jq -e '[.[] | select(.workspace.id == 6 and .class == \"com.mitchellh.ghostty\")] | " + jq + " == " + str(expected) + "'",
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
          machine.wait_until_succeeds(
              "pgrep -u alice -f 'qs -p /home/alice/.local/share/hyprsimple/default/quickshell'",
              timeout=60,
          )

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
          # Run Part 1 of docs/uninstall.md exactly as a reader would.
          guide = open("${../docs/uninstall.md}").read()
          part1 = guide.split("## Part 1")[1].split("## Part 2")[0]
          blocks = re.findall(r"```sh\n(.*?)```", part1, re.S)
          assert len(blocks) == 4, f"expected 4 command blocks in Part 1, found {len(blocks)}"
          for block in blocks:
              print(user(block + " 2>&1", check=False)[1])
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
