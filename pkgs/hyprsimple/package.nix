{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  coreutils,
  diffutils,
  findutils,
  git,
  gnugrep,
  gnused,
  util-linux,
  xdg-user-dirs,
  xdg-user-dirs-gtk,
}:

# hyprsimple's own files, prepared for NixOS. This is the tree upstream's
# install.sh copies to ~/.local/share/hyprsimple. On NixOS the module links it
# at /etc/hyprsimple/source and `hyprsimple-install` / `hyprsimple-update`
# copy it into place for each user, so every user gets ordinary, writable
# files, the way hyprsimple expects them.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hyprsimple";
  version = "0.4.8";

  src = fetchFromGitHub {
    owner = "rizukirr";
    repo = "hyprsimple";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/dnsJANuYTFMmbozGwyy9YzdAI3hmtMjwIir/Kw7RnY=";
  };

  # Patches 1 to 4 and 6 only add a branch taken when /etc/hyprsimple/source
  # exists, which the NixOS module creates; everywhere else those scripts
  # behave exactly as upstream wrote them. Patch 5 fixes a bug that affects
  # every distribution, until upstream has the fix.
  patches = [
    # hyprsimple-update: take the version from the NixOS configuration instead
    # of git, and leave packages to NixOS instead of pacman.
    ./patches/0001-nixos-update-from-system-configuration.patch
    # hyprsimple-plugin: a plugin's packages are checked against the NixOS
    # configuration instead of installed with pacman or an AUR helper.
    ./patches/0002-nixos-plugin-dependencies.patch
    # hyprsimple-migrate: migrations' pacman queries are answered by a shim.
    ./patches/0003-nixos-migrations-pacman-shim.patch
    # hyprsimple-debug: report NixOS facts instead of pacman's.
    ./patches/0004-nixos-debug-report.patch
    # bashrc.sh: set zoxide up after starship, so zoxide stops warning on the
    # first `cd` of every terminal that it is "not initialized at the end".
    ./patches/0005-bashrc-initialize-zoxide-last.patch
    # hyprsimple-session.sh: on NixOS, point to the setting that adds the
    # "Hyprsimple" login entry, instead of writing to /usr/local/share.
    ./patches/0006-nixos-login-entry.patch
  ];

  # Paths that only exist on an FHS distribution. --replace-fail makes a
  # hyprsimple update that moves any of them fail to build, rather than ship
  # quietly broken.
  postPatch = ''
    # /bin/bash does not exist on NixOS. /usr/bin/env does, and finds bash on
    # PATH, which keeps these scripts working after garbage collection (a
    # /nix/store interpreter would not survive in copies under ~/.local/bin).
    while IFS= read -r -d "" file; do
      sed -i -e '1s|^#!/bin/bash|#!/usr/bin/env bash|' -e '1s|^#!/bin/zsh|#!/usr/bin/env zsh|' -- "$file"
    done < <(grep -rlIZ -e '^#!/bin/bash' -e '^#!/bin/zsh' .)

    # The user units hyprsimple installs set PATH by hand, to directories that
    # are empty on NixOS. These are NixOS's own, in the order a login shell has.
    for unit in .config/systemd/user/battery-monitor.service \
                .config/systemd/user/hyprsimple-audio-autoswitch.service; do
      substituteInPlace "$unit" \
        --replace-fail 'Environment=PATH=/usr/local/bin:/usr/bin:/bin' \
                       'Environment=PATH=%h/.local/bin:/run/wrappers/bin:%h/.nix-profile/bin:%h/.local/state/nix/profile/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin'
    done

    # The microphone noise filter (rnnoise-plugin, linked into the system profile).
    substituteInPlace .config/pipewire/pipewire.conf.d/99-input-denoising.conf \
      --replace-fail /usr/lib/ladspa/librnnoise_ladspa.so \
                     /run/current-system/sw/lib/ladspa/librnnoise_ladspa.so

    # Cursor themes live in the Nix profiles, not in /usr/share/icons.
    substituteInPlace .local/bin/theme-switcher.sh \
      --replace-fail \
        'for dir in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do' \
        'for dir in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons "$HOME/.nix-profile/share/icons" "/etc/profiles/per-user/$USER/share/icons" /run/current-system/sw/share/icons; do'

    # Hyprland's Lua stubs, for editors (programs.hyprland links share/hypr).
    substituteInPlace .config/hypr/.luarc.json \
      --replace-fail /usr/share/hypr/stubs /run/current-system/sw/share/hypr/stubs
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hyprsimple
    cp -r . $out/share/hyprsimple/

    # The per-user installer and the sync step hyprsimple-update calls.
    install -Dm755 ${./hyprsimple-nixos.sh} $out/bin/hyprsimple-nixos
    substituteInPlace $out/bin/hyprsimple-nixos \
      --replace-fail '#!/usr/bin/env bash' '#!${lib.getExe bash}' \
      --replace-fail '@runtimePath@' '${
        lib.makeBinPath [
          coreutils
          diffutils
          findutils
          git
          gnugrep
          gnused
          util-linux
          xdg-user-dirs
          xdg-user-dirs-gtk
        ]
      }'

    cat >$out/bin/hyprsimple-install <<EOF
    #!${lib.getExe bash}
    exec $out/bin/hyprsimple-nixos install "\$@"
    EOF
    chmod +x $out/bin/hyprsimple-install

    # hyprsimple's bashrc.sh, zsh.sh and fish.fish alias these to the scripts
    # in ~/.local/bin. These do the same from any shell, including one where
    # the shell integration is not wired up yet.
    for name in update migrate refresh-config debug; do
      cat >$out/bin/hyprsimple-$name <<EOF
    #!${lib.getExe bash}
    script="\$HOME/.local/bin/hyprsimple-$name.sh"
    if [[ ! -x \$script ]]; then
      echo "hyprsimple is not set up for \$(id -un) yet. Run hyprsimple-install first." >&2
      exit 1
    fi
    exec "\$script" "\$@"
    EOF
      chmod +x $out/bin/hyprsimple-$name
    done

    # The pieces `hyprsimple-nixos gpu` puts together into a gpu.nix.
    install -Dm644 -t $out/share/hyprsimple-nix/gpu ${./gpu}/*.part
    substituteInPlace $out/bin/hyprsimple-nixos \
      --replace-fail '@gpuParts@' "$out/share/hyprsimple-nix/gpu"

    # The "Hyprsimple" login entry, written by hyprsimple-session.sh itself so
    # that it stays exactly upstream's. programs.hyprsimple.loginEntry.enable
    # installs it.
    mkdir -p $out/share/hyprsimple-nix/wayland-sessions
    HYPRSIMPLE_SESSION_DIR=$out/share/hyprsimple-nix/wayland-sessions \
      ${lib.getExe bash} .local/bin/hyprsimple-session.sh
    grep -qx 'Exec=uwsm start .*' $out/share/hyprsimple-nix/wayland-sessions/hyprsimple.desktop

    install -Dm755 ${./pacman-shim.sh} $out/libexec/hyprsimple-nix/shims/pacman
    substituteInPlace $out/libexec/hyprsimple-nix/shims/pacman \
      --replace-fail '#!/usr/bin/env bash' '#!${lib.getExe bash}'

    runHook postInstall
  '';

  # share/hyprsimple must keep the /usr/bin/env shebangs set above: these
  # files are copied into home directories, where a /nix/store interpreter
  # would dangle after the next garbage collection. The scripts in bin/ and
  # libexec/ already name bash by store path, which is safe there because the
  # system profile keeps them alive.
  dontPatchShebangs = true;

  meta = {
    description = "Minimal Hyprland desktop (hyprsimple), packaged for NixOS";
    longDescription = ''
      hyprsimple is a set of Hyprland dotfiles for Arch Linux by rizukirr: a
      Quickshell bar, 40 themes with one-key switching, visual theme and
      wallpaper pickers, and in-place updates with migrations. This package
      holds its files prepared for NixOS, and the hyprsimple-install and
      hyprsimple-nixos tools that set it up per user.
    '';
    homepage = "https://github.com/rizukirr/hyprsimple";
    # Upstream does not include a license file at this version. This
    # expression only fetches hyprsimple from its GitHub repository, the same
    # way `git clone` does, and no binary cache redistributes it.
    platforms = lib.platforms.linux;
    mainProgram = "hyprsimple-install";
  };
})
