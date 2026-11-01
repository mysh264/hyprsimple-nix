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

  testScript = ''
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

    with subtest("the theme switcher reached GTK through dconf"):
        user("gsettings get org.gnome.desktop.interface color-scheme | grep -q prefer-dark")
        user("gsettings get org.gnome.desktop.interface icon-theme | grep -q Yaru")
        user("test -s ~/.config/dconf/user")
        user("test -L ~/.config/hypr/theme-active.lua")

    with subtest("muslimtify is installed as a plugin with a unit that survives upgrades"):
        user("hyprsimple-plugin list | grep -q '^muslimtify'")
        user("grep -Eq '^ExecStart=\"?/run/current-system/sw/bin/muslimtify\"? daemon run$' ~/.config/systemd/user/muslimtify.service")

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

    with subtest("a Hyprland session through UWSM"):
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

    with subtest("hyprsimple-update with nothing new"):
        out = user("hyprsimple-update 2>&1")
        print(out)
        assert "already what your NixOS configuration provides" in out
        assert "hyprsimple is up to date" in out

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
        assert "0.4.5 -> 9.9.9" in out, "sync did not report the version change"
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
