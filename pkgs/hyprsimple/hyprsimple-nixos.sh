#!/usr/bin/env bash
# hyprsimple-nixos: the per-user half of hyprsimple on NixOS.
#
# The NixOS module (programs.hyprsimple) installs the packages and services
# hyprsimple needs, and links the hyprsimple version it provides at
# /etc/hyprsimple/source. This tool puts that version where hyprsimple expects
# it, in ~/.local/share/hyprsimple, and does the parts of hyprsimple's own
# install.sh that touch your home directory: configs, helper scripts, user
# services, the default theme and the shell integration.
#
# It never asks pacman for anything and never needs sudo.

set -eEo pipefail

# The tools this script calls itself, ahead of whatever the caller has.
PATH="@runtimePath@${PATH:+:$PATH}"

ETC=/etc/hyprsimple
export HYPRSIMPLE_PATH="${HYPRSIMPLE_PATH:-$HOME/.local/share/hyprsimple}"
STATE_DIR="$HOME/.local/state/hyprsimple"
PLUGIN_ROOT="${HYPRSIMPLE_PLUGIN_ROOT:-$HOME/.local/share/hyprsimple-plugins}"
MUSLIMTIFY_URL="https://github.com/muslimtify-org/muslimtify-hyprsimple.git"

if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BOLD='' NC=''
fi

say() { echo -e "$*"; }
note() { echo -e "${YELLOW}$*${NC}"; }
good() { echo -e "${GREEN}$*${NC}"; }
die() {
  echo -e "${RED}hyprsimple-nixos: $*${NC}" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: hyprsimple-nixos <command> [options]

Commands:
  install [-y]     Set hyprsimple up for the current user: the equivalent of
                   hyprsimple's ./install.sh, minus everything NixOS already
                   did. Also available as `hyprsimple-install`.
  sync             Copy the hyprsimple version your NixOS configuration
                   provides into ~/.local/share/hyprsimple. hyprsimple-update
                   runs this for you.
  check-packages   List packages this hyprsimple version wants that your NixOS
                   configuration does not provide.
  status           Show which version is installed and which one NixOS provides.
  gpu [--file]     Show the graphics settings this computer needs, as a
                   gpu.nix for your NixOS configuration. --file prints only
                   the file, for: hyprsimple-nixos gpu --file | sudo tee /etc/nixos/gpu.nix

Options for install:
  -y, --yes        Do not ask before moving existing configs aside.
  --no-plugins     Do not install the default plugins (muslimtify).
EOF
}

# ---- Facts from the NixOS configuration -------------------------------------

require_module() {
  [[ -e $ETC/source ]] ||
    die "this NixOS configuration does not enable hyprsimple ($ETC/source is missing).
Add 'programs.hyprsimple.enable = true;' to it and rebuild."
}

system_source() { readlink -f -- "$ETC/source"; }

# Written by the module: HYPRSIMPLE_NIX_DEFAULT_THEME, HYPRSIMPLE_NIX_MUSLIMTIFY.
load_settings() {
  HYPRSIMPLE_NIX_DEFAULT_THEME="deep-sea"
  HYPRSIMPLE_NIX_MUSLIMTIFY=0
  # shellcheck source=/dev/null
  [[ -r $ETC/settings ]] && source "$ETC/settings"
}

# ---- The local repository behind HYPRSIMPLE_PATH ----------------------------
#
# HYPRSIMPLE_PATH is a git repository with one commit per version NixOS has
# delivered. hyprsimple-update reads the commit from before a sync to report
# which shipped configs changed and to restart the bar when it changed, exactly
# as it does after a git pull on Arch.

hgit() {
  git -C "$HYPRSIMPLE_PATH" \
    -c safe.directory='*' \
    -c core.autocrlf=false \
    -c core.fileMode=true \
    -c core.symlinks=true \
    -c core.hooksPath=/dev/null \
    -c commit.gpgsign=false \
    -c user.name=hyprsimple-nix \
    -c user.email=hyprsimple-nix@localhost \
    "$@"
}

# The git tree of a directory, computed without touching HYPRSIMPLE_PATH's
# working tree or index. --force, because a file upstream tracks is shipped
# even when one of its .gitignore patterns would match it.
tree_of() {
  local dir=$1 index
  index=$(mktemp "${TMPDIR:-/tmp}/hyprsimple-index.XXXXXX")
  rm -f "$index"
  GIT_INDEX_FILE=$index hgit --work-tree="$dir" add --all --force -- . >/dev/null
  GIT_INDEX_FILE=$index hgit write-tree
  rm -f "$index"
}

looks_like_hyprsimple() {
  [[ -f $1/version && -d $1/default ]] || [[ -f $1/install.sh ]]
}

dir_is_empty() {
  [[ -z $(find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null) ]]
}

# Put the version NixOS provides into HYPRSIMPLE_PATH. Sets DELIVERED=1 when
# that changed anything, and leaves it 0 when the version was already there.
DELIVERED=0
deliver() {
  local src version tree head_tree commit
  src=$(system_source)
  version=$(cat "$src/version" 2>/dev/null || echo unknown)

  if [[ ! -d $HYPRSIMPLE_PATH/.git ]]; then
    # First delivery, or an install that predates this repository: start one.
    mkdir -p "$HYPRSIMPLE_PATH"
    git init -q -b nixos "$HYPRSIMPLE_PATH"
  fi

  if hgit rev-parse -q --verify HEAD >/dev/null; then
    if [[ -n $(hgit status --porcelain) ]]; then
      echo -e "${RED}$HYPRSIMPLE_PATH has local changes.${NC}" >&2
      echo "Commit, stash, or discard them, then run hyprsimple-update again:" >&2
      echo "  git -C $HYPRSIMPLE_PATH status" >&2
      return 1
    fi
  fi

  tree=$(tree_of "$src")
  head_tree=$(hgit rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null || true)
  if [[ $tree == "$head_tree" ]]; then
    return 0
  fi

  if [[ -n $head_tree ]]; then
    commit=$(hgit commit-tree "$tree" -p HEAD -m "hyprsimple $version from NixOS" -m "Source: $src")
  else
    commit=$(hgit commit-tree "$tree" -m "hyprsimple $version from NixOS" -m "Source: $src")
  fi
  # Writes only the files that differ, with ordinary writable permissions,
  # and removes the ones this version no longer ships.
  hgit reset -q --hard "$commit"
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$src" >"$STATE_DIR/nix-source"
  DELIVERED=1
}

cmd_sync() {
  require_module
  [[ -d $HYPRSIMPLE_PATH ]] || die "hyprsimple is not set up for $(id -un) yet. Run hyprsimple-install."
  # First, so that it happens even when the delivery below stops.
  repair_user_units
  local before after
  before=$(cat "$HYPRSIMPLE_PATH/version" 2>/dev/null || echo unknown)
  deliver
  after=$(cat "$HYPRSIMPLE_PATH/version" 2>/dev/null || echo unknown)
  if ((DELIVERED)); then
    good "hyprsimple $before -> $after, from your NixOS configuration."
  else
    good "hyprsimple $after is already what your NixOS configuration provides."
    echo "For a newer one, update the hyprsimple-nix flake input, rebuild, and run hyprsimple-update again."
  fi
}

# ---- Packages --------------------------------------------------------------

# Every Arch package name in packages.txt and aur-packages.txt of a tree.
listed_packages() {
  local dir=$1 list
  for list in packages.txt aur-packages.txt; do
    [[ -f $dir/$list ]] || continue
    sed -e 's/#.*//' -e 's/[[:space:]]//g' "$dir/$list" | grep -v '^$' || true
  done
}

cmd_check_packages() {
  require_module
  local dir=$HYPRSIMPLE_PATH pkg
  [[ -f $dir/packages.txt ]] || dir=$(system_source)
  local -a unknown=() excluded=()
  while IFS= read -r pkg; do
    if ! grep -qxF -- "$pkg" "$ETC/arch-packages" 2>/dev/null; then
      unknown+=("$pkg")
    elif grep -qxF -- "$pkg" "$ETC/arch-packages-excluded" 2>/dev/null; then
      excluded+=("$pkg")
    fi
  done < <(listed_packages "$dir")

  if ((${#excluded[@]})); then
    note "Left out by programs.hyprsimple.excludePackages: ${excluded[*]}"
  fi
  if ((${#unknown[@]} == 0)); then
    good "Every package this hyprsimple version lists is provided by your NixOS configuration."
    return 0
  fi
  note "This hyprsimple version lists packages hyprsimple-nix does not provide yet:"
  printf '  %s\n' "${unknown[@]}"
  echo "Updating hyprsimple-nix usually fixes this. Until then, features that need"
  echo "them may not work; add an equivalent to environment.systemPackages if you need one."
  return 1
}

cmd_status() {
  require_module
  local src installed=unknown provided
  src=$(system_source)
  provided=$(cat "$src/version" 2>/dev/null || echo unknown)
  [[ -f $HYPRSIMPLE_PATH/version ]] && installed=$(cat "$HYPRSIMPLE_PATH/version")
  echo "Provided by NixOS:  hyprsimple $provided ($src)"
  if [[ -d $HYPRSIMPLE_PATH ]]; then
    echo "Installed for $(id -un): hyprsimple $installed ($HYPRSIMPLE_PATH)"
    if [[ -d $HYPRSIMPLE_PATH/.git ]] && [[ $(tree_of "$src") != "$(hgit rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null)" ]]; then
      note "Your copy differs from what NixOS provides. Run hyprsimple-update."
    fi
  else
    note "Not set up for $(id -un) yet. Run hyprsimple-install."
  fi
}

# ---- install ---------------------------------------------------------------

# The same rule as install.sh: the first backup keeps the name .backup, any
# later one gets a timestamp, and nothing is deleted. A target that already
# holds exactly what is about to be written is left alone.
backup_if_exists() {
  local target=$1 source=${2-}
  [[ -e $target || -L $target ]] || return 0
  if [[ -n $source && -f $source && -f $target ]] && cmp -s "$source" "$target"; then
    return 0
  fi
  local backup="$target.backup"
  if [[ -e $backup || -L $backup ]]; then
    backup="$target.backup.$(date +%s)"
  fi
  note "Backing up existing $target to $backup"
  mv -- "$target" "$backup"
}

# A path Home Manager (or another Nix tool) manages is a link into the store.
# Moving it aside works, but the tool that owns it will want it back.
store_managed() {
  local target=$1
  [[ -L $target && $(readlink -f -- "$target") == /nix/store/* ]] && return 0
  [[ -d $target && ! -L $target ]] &&
    find "$target" -maxdepth 3 -type l -lname '/nix/store/*' -print -quit 2>/dev/null | grep -q .
}

confirm_takeover() {
  local -a present=() managed=()
  local item name
  for item in "$HYPRSIMPLE_PATH/.config"/*; do
    name=$(basename "$item")
    [[ $name == systemd ]] && continue
    if [[ -e $HOME/.config/$name || -L $HOME/.config/$name ]]; then
      if [[ -f $item && -f $HOME/.config/$name ]] && cmp -s "$item" "$HOME/.config/$name"; then
        continue
      fi
      present+=("$HOME/.config/$name")
      store_managed "$HOME/.config/$name" && managed+=("$HOME/.config/$name")
    fi
  done
  ((${#present[@]})) || return 0

  say ""
  note "hyprsimple brings its own config for these, so yours will be moved aside"
  note "(to <name>.backup, nothing is deleted):"
  printf '  %s\n' "${present[@]/#"$HOME"/\~}"
  if ((${#managed[@]})); then
    say ""
    echo -e "${RED}Some of them are links into /nix/store, which usually means Home Manager owns them:${NC}"
    printf '  %s\n' "${managed[@]/#"$HOME"/\~}"
    echo "Remove them from your Home Manager configuration, or Home Manager will"
    echo "refuse to switch, or put its version back over hyprsimple's."
  fi
  if ((ASSUME_YES)) || [[ ! -t 0 ]]; then
    return 0
  fi
  say ""
  local reply
  read -rp "Continue? [Y/n] " reply
  [[ -z $reply || $reply == [yY]* ]] || die "nothing was changed."
}

copy_configs() {
  local item name target
  for item in "$HYPRSIMPLE_PATH/.config"/*; do
    name=$(basename "$item")
    target="$HOME/.config/$name"
    if [[ $name == systemd ]]; then
      # Merged unit by unit instead of replacing the directory: ~/.config/systemd
      # also holds your own units and every `systemctl --user enable` link.
      local unit rel
      while IFS= read -r -d '' unit; do
        rel=${unit#"$item"/}
        mkdir -p "$(dirname "$target/$rel")"
        backup_if_exists "$target/$rel" "$unit"
        cp -P -- "$unit" "$target/$rel"
      done < <(find "$item" \( -type f -o -type l \) -print0)
      good "Copied: systemd user units"
      continue
    fi
    backup_if_exists "$target" "$item"
    mkdir -p "$HOME/.config"
    if [[ -d $item ]]; then
      cp -r -- "$item" "$target"
    else
      cp -- "$item" "$target"
    fi
    good "Copied: $name"
  done
}

copy_scripts() {
  local script target
  mkdir -p "$HOME/.local/bin"
  for script in "$HYPRSIMPLE_PATH/.local/bin"/*.sh "$HYPRSIMPLE_PATH/.local/bin"/*.fish "$HYPRSIMPLE_PATH/.local/bin/hyprsimple-plugin"; do
    [[ -f $script ]] || continue
    target="$HOME/.local/bin/$(basename "$script")"
    backup_if_exists "$target" "$script"
    cp -- "$script" "$target"
    chmod +x "$target"
  done
  good "Installed hyprsimple's scripts to ~/.local/bin"

  if [[ -d $HYPRSIMPLE_PATH/.local/share ]]; then
    local item
    mkdir -p "$HOME/.local/share"
    for item in "$HYPRSIMPLE_PATH/.local/share"/*; do
      [[ -e $item ]] || continue
      target="$HOME/.local/share/$(basename "$item")"
      backup_if_exists "$target" "$item"
      cp -r -- "$item" "$target"
    done
  fi
}

user_manager_up() { systemctl --user show-environment >/dev/null 2>&1; }

# On NixOS, `systemctl --user enable` of a unit the system ships (hyprpaper,
# hyprpolkitagent, hyprsunset) links that unit's file from /nix/store into
# ~/.config/systemd/user. systemd then reads that file instead of the
# system's: the version installed that day, kept after every update and
# rebuild, and gone with the next garbage collection, which leaves no
# wallpaper, no password prompts and no night light. This points every such
# link back at /etc/systemd/user, which always holds the current system's
# unit. A unit file link is removed (the one in /etc/systemd/user takes its
# place); a wants link is repointed. Says whether anything changed.
UNPINNED=()
unpin_user_units() {
  local dir=$HOME/.config/systemd/user link name
  UNPINNED=()
  [[ -d $dir ]] || return 1
  while IFS= read -r -d '' link; do
    name=$(basename "$link")
    [[ $(readlink "$link") == /nix/store/* && -e /etc/systemd/user/$name ]] || continue
    if [[ $(dirname "$link") == "$dir" ]]; then
      rm -f -- "$link"
      UNPINNED+=("$name")
    else
      ln -sfn -- "/etc/systemd/user/$name" "$link"
    fi
  done < <(find "$dir" -maxdepth 2 -type l -print0)
  ((${#UNPINNED[@]} > 0))
}

# For hyprsimple-update, and installs from before the fix: repoint the units,
# and restart the ones the session runs, so the current version runs now.
repair_user_units() {
  unpin_user_units || return 0
  user_manager_up || return 0
  systemctl --user daemon-reload
  if systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user restart "${UNPINNED[@]}" >/dev/null 2>&1 || true
  fi
  good "Now from your current system: ${UNPINNED[*]}"
}

enable_user_units() {
  if ! user_manager_up; then
    note "Your systemd user manager is not reachable from here, so the user services"
    note "were not enabled. Run hyprsimple-install again from your own login session."
    FAILED+=("user services: rerun hyprsimple-install from your own login session")
    return 0
  fi
  systemctl --user daemon-reload

  # Wanted by graphical-session.target, so the session starts them. Enabled,
  # not started, for the reason install.sh gives: from a TTY there is no
  # compositor for them to talk to yet.
  local unit
  for unit in battery-monitor.timer hyprsimple-audio-autoswitch.service; do
    if [[ -f $HOME/.config/systemd/user/$unit ]]; then
      systemctl --user enable "$unit" >/dev/null 2>&1 || FAILED+=("systemctl --user enable $unit")
    fi
  done

  # hyprsunset runs from the unit its package ships, with hyprsimple's drop-in
  # raising Restart to always, linked so an update reaches it.
  if systemctl --user cat hyprsunset.service >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/systemd/user/hyprsunset.service.d"
    ln -sfn "$HYPRSIMPLE_PATH/default/systemd/hyprsunset-restart.conf" \
      "$HOME/.config/systemd/user/hyprsunset.service.d/10-hyprsimple.conf"
    systemctl --user daemon-reload
    systemctl --user enable hyprsunset.service >/dev/null 2>&1 || FAILED+=("systemctl --user enable hyprsunset.service")
  fi

  for unit in hyprpaper.service hyprpolkitagent.service; do
    systemctl --user enable "$unit" >/dev/null 2>&1 || FAILED+=("systemctl --user enable $unit")
  done
  # Enabled, but without the links into /nix/store that enable leaves.
  if unpin_user_units; then
    systemctl --user daemon-reload
  fi
  if systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user start hyprpaper.service hyprpolkitagent.service >/dev/null 2>&1 || true
  fi
  good "Enabled the hyprsimple user services"
}

install_plugins() {
  ((HYPRSIMPLE_NIX_MUSLIMTIFY)) || return 0
  ((SKIP_PLUGINS)) && return 0
  local manager="$HOME/.local/bin/hyprsimple-plugin"
  local -a action
  if [[ -d $PLUGIN_ROOT/muslimtify ]]; then
    action=(enable muslimtify)
  elif [[ -n ${HYPRSIMPLE_NIX_MUSLIMTIFY_SOURCE:-} ]]; then
    # A local clone, for machines without network access and for the tests.
    action=(install --local "$HYPRSIMPLE_NIX_MUSLIMTIFY_SOURCE")
  else
    action=(install "$MUSLIMTIFY_URL")
  fi
  note "Installing the muslimtify plugin (prayer times on the bar)..."
  if "$manager" "${action[@]}"; then
    good "muslimtify plugin enabled"
  else
    FAILED+=("muslimtify plugin: retry with  hyprsimple-plugin ${action[*]}")
  fi
}

hardware_hints() {
  command -v lspci >/dev/null 2>&1 || return 0
  local gpus
  gpus=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)
  if grep -qi nvidia <<<"$gpus" && ! grep -q '^nvidia ' /proc/modules 2>/dev/null; then
    HINTS+=("An NVIDIA GPU is present but its driver is not loaded. On NixOS the driver is part of your configuration: see 'NVIDIA' in the hyprsimple-nix README.")
  fi
  if grep -qi intel <<<"$gpus" && [[ -n $(compgen -G '/sys/class/power_supply/BAT*') ]] &&
    ! systemctl is-enabled --quiet thermald 2>/dev/null; then
    HINTS+=("hyprsimple's installer enables thermald on Intel laptops. On NixOS that is 'services.thermald.enable = true;'.")
  fi
}

cmd_install() {
  ASSUME_YES=0
  SKIP_PLUGINS=0
  while (($#)); do
    case $1 in
      -y | --yes) ASSUME_YES=1 ;;
      --no-plugins) SKIP_PLUGINS=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option for install: $1" ;;
    esac
    shift
  done

  ((EUID != 0)) || die "run hyprsimple-install as the user who will use hyprsimple, not as root."
  require_module
  load_settings
  FAILED=()
  HINTS=()

  mkdir -p "$STATE_DIR"
  local log="$STATE_DIR/install.log"
  : >"$log"
  exec > >(tee -a "$log") 2>&1

  local src version
  src=$(system_source)
  version=$(cat "$src/version" 2>/dev/null || echo unknown)
  say "======================================"
  say "  hyprsimple $version for NixOS"
  say "======================================"

  # 1. hyprsimple itself, at the path every hyprsimple script reads.
  if [[ -e $HYPRSIMPLE_PATH && ! -d $HYPRSIMPLE_PATH/.git ]]; then
    if dir_is_empty "$HYPRSIMPLE_PATH"; then
      :
    elif looks_like_hyprsimple "$HYPRSIMPLE_PATH"; then
      # A copy install.sh or an earlier manual install left. Like install.sh,
      # it is replaced: it is hyprsimple's, not yours.
      rm -rf -- "$HYPRSIMPLE_PATH"
    else
      die "$HYPRSIMPLE_PATH exists but does not look like hyprsimple. Move it aside and run this again."
    fi
  elif [[ -d $HYPRSIMPLE_PATH/.git ]] && ! hgit rev-parse -q --verify refs/heads/nixos >/dev/null; then
    # A git checkout of upstream (bootstrap.sh). Its history is upstream's and
    # stays on GitHub; NixOS delivers versions from now on.
    rm -rf -- "$HYPRSIMPLE_PATH"
  fi
  deliver
  good "hyprsimple $version is in $HYPRSIMPLE_PATH"

  # 2. A fresh install already carries every fix, so every migration counts as
  # done, exactly as install.sh records it.
  rm -f -- "$HOME/.local/bin/hyprsimple-muslimtify.sh"
  local migration_state="$STATE_DIR/migrations"
  mkdir -p "$migration_state/skipped"
  local migration
  for migration in "$HYPRSIMPLE_PATH/migrations"/*.sh; do
    [[ -f $migration ]] && touch "$migration_state/$(basename "$migration")"
  done

  # 3. Configs and scripts.
  confirm_takeover
  say ""
  note "Copying configuration files..."
  copy_configs
  copy_scripts

  # 4. User services.
  say ""
  note "Enabling user services..."
  enable_user_units

  # 5. The default theme, rendered and applied the way install.sh does it.
  say ""
  note "Applying the default theme (${HYPRSIMPLE_NIX_DEFAULT_THEME})..."
  mkdir -p "$HOME/.cache" "$HOME/.config/btop/themes"
  ln -sfn "$HYPRSIMPLE_PATH/default/hypr" "$HOME/.config/hypr/hyprsimple"
  if [[ ! -d $HOME/.config/hypr/themes/$HYPRSIMPLE_NIX_DEFAULT_THEME ]]; then
    note "There is no theme called '$HYPRSIMPLE_NIX_DEFAULT_THEME', using deep-sea."
    HYPRSIMPLE_NIX_DEFAULT_THEME=deep-sea
  fi
  if THEME_SWITCHER_NO_RELOAD=1 bash "$HOME/.local/bin/theme-switcher.sh" "$HYPRSIMPLE_NIX_DEFAULT_THEME"; then
    good "Theme initialized"
  else
    FAILED+=("theme: run  theme-switcher.sh $HYPRSIMPLE_NIX_DEFAULT_THEME  once you are logged in")
  fi
  # The home folders (Documents, Downloads, Music...), which a desktop
  # environment would have made. The login does it again, and adds them to the
  # file manager's sidebar, which needs the display this may not have.
  xdg-user-dirs-update >/dev/null 2>&1 || true
  if [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
    xdg-user-dirs-gtk-update >/dev/null 2>&1 || true
  fi
  mkdir -p "$HOME/Videos" "$HOME/Pictures"

  # 6. Shell integration (aliases such as hyprsimple-update, starship, zoxide).
  say ""
  note "Configuring shell integration..."
  if ! bash "$HOME/.local/bin/terminal.sh"; then
    HINTS+=("Shell integration was not written. If your shell rc file is managed by Nix, source ~/.local/bin/bashrc.sh (or zsh.sh, fish.fish) from there.")
  fi

  # 7. Default plugins.
  install_plugins

  # 8. A running session picks the changes up now; otherwise the next login does.
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    "$HOME/.local/bin/hyprsimple-restart-bar.sh" || true
  fi
  # install.sh sets the microphone to 65%, which suits the noise suppression
  # filter in ~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf.
  pactl set-source-volume @DEFAULT_SOURCE@ 65% >/dev/null 2>&1 || true
  # And a power profile to start from: balanced on a laptop, performance on a desktop.
  if command -v powerprofilesctl >/dev/null 2>&1; then
    if bash "$HOME/.local/bin/hyprsimple-hw-battery.sh" 2>/dev/null; then
      powerprofilesctl set balanced >/dev/null 2>&1 || true
    else
      powerprofilesctl set performance >/dev/null 2>&1 || true
    fi
  fi
  hardware_hints

  say ""
  if ((${#FAILED[@]})); then
    echo -e "${RED}======================================"
    echo "  Installed, but ${#FAILED[@]} step(s) need another go"
    echo -e "======================================${NC}"
    printf '  %s\n' "${FAILED[@]}"
  else
    good "======================================"
    good "  hyprsimple is set up for $(id -un)"
    good "======================================"
  fi
  if ((${#HINTS[@]})); then
    say ""
    local hint
    for hint in "${HINTS[@]}"; do note "* $hint"; done
  fi
  say ""
  echo -e "${BOLD}Next:${NC}"
  echo "  1. Log out, and log in to 'Hyprland (UWSM)' from your display manager,"
  echo "     or from a TTY run:  uwsm start hyprland-uwsm.desktop"
  echo "  2. Set up your monitors in ~/.config/hypr/monitors.lua"
  echo "  3. After a NixOS rebuild that brings a new hyprsimple, run: hyprsimple-update"
  echo ""
  echo "Log saved to $log"
}

# ---- gpu -------------------------------------------------------------------
#
# hyprsimple's install.sh looks at the graphics hardware and installs drivers
# for it. On NixOS drivers belong in the configuration, so this looks at the
# same hardware and writes the configuration instead: a gpu.nix to import.

GPU_PARTS="@gpuParts@"
GPU_GUIDE="https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md"

# lspci's address (0000:01:00.0, in hexadecimal) in the form NixOS wants
# (PCI:1:0:0, in decimal), with the domain after an @ when it is not 0.
nixos_bus_id() {
  local domain bus device function
  IFS=':.' read -r domain bus device function <<<"$1"
  if ((16#$domain == 0)); then
    printf 'PCI:%d:%d:%d\n' "$((16#$bus))" "$((16#$device))" "$((16#$function))"
  else
    printf 'PCI:%d@%d:%d:%d\n' "$((16#$bus))" "$((16#$domain))" "$((16#$device))" "$((16#$function))"
  fi
}

# Which driver an NVIDIA card needs, from the chip name lspci shows (TU117M,
# GA104, AD107M, GP108M, GK104...) or, failing that, its marketing name.
#   current  Turing and newer: GTX 1600, RTX 2000 and later, MX 450 and later
#   older    Maxwell, Pascal, Volta: GTX 900 and 1000, MX 100 to 300
#   ancient  Kepler and before: too old for Hyprland with NVIDIA's driver
nvidia_generation() {
  local name=$1
  local current_chip='(^|[^A-Z])(TU|GA|AD|GB|GH)[0-9]{3}'
  local older_chip='(^|[^A-Z])(GP|GM|GV)[0-9]{3}'
  local ancient_chip='(^|[^A-Z])(GK|GF|GT|NV)[0-9]{2,3}|(^|[^A-Z])G[0-9]{2}[^0-9]'
  local current_name='GTX 16[0-9]{2}|RTX [2-9][0-9]{3}|RTX PRO|Quadro RTX|RTX A[0-9]{4}|MX ?[4-9][0-9]{2}'
  local older_name='GTX (9[0-9]{2}|10[0-9]{2})|GT 10[0-9]{2}|Quadro [PM][0-9]{3,4}|MX ?[1-3][0-9]{2}|Titan (X|Xp|V)'
  if [[ $name =~ $current_chip ]]; then
    echo current
  elif [[ $name =~ $older_chip ]]; then
    echo older
  elif [[ $name =~ $ancient_chip ]]; then
    echo ancient
  elif [[ $name =~ $current_name ]]; then
    echo current
  elif [[ $name =~ $older_name ]]; then
    echo older
  else
    echo unknown
  fi
}

# A part of gpu.nix, from the files in $GPU_PARTS.
gpu_part() { cat "$GPU_PARTS/$1.part"; }

cmd_gpu() {
  local file_only=0
  case ${1-} in
    --file) file_only=1 ;;
    "") ;;
    -h | --help)
      echo "Usage: hyprsimple-nixos gpu [--file]"
      echo "Shows the graphics settings this computer needs. --file prints only gpu.nix."
      return 0
      ;;
    *) die "unknown option for gpu: $1" ;;
  esac

  # Both can be pointed elsewhere, which is how the tests describe machines.
  local sysfs=${HYPRSIMPLE_NIX_SYSFS:-/sys} listing
  if [[ -n ${HYPRSIMPLE_NIX_LSPCI_FILE:-} ]]; then
    listing=$(cat "$HYPRSIMPLE_NIX_LSPCI_FILE")
  else
    listing=$(lspci -D -nn 2>/dev/null) || die "lspci could not list this computer's devices."
  fi

  local laptop=0
  compgen -G "$sysfs/class/power_supply/BAT*" >/dev/null && laptop=1

  # One line per graphics device: VGA [0300], 3D [0302] and display [0380]
  # controllers, which is where lspci puts every kind of GPU.
  local line slot ids vendor text name
  local intel_slot="" amd_slot="" nvidia_slot="" nvidia_name="" amd_old=0 vm=0
  local -a found=()
  local graphics_class='\[03(00|02|80)\]: '
  local pci_ids='\[([0-9a-f]{4}):([0-9a-f]{4})\]'
  local last_bracket='\[([^][]*)\][[:space:]]*$'
  local old_radeon='Tahiti|Pitcairn|Cape Verde|Oland|Hainan|Curacao|Bonaire|Hawaii|Kaveri|Kabini|Mullins|Neptune|Venus|Mars|Opal|Saturn|Strato'
  while IFS= read -r line; do
    [[ $line =~ $graphics_class ]] || continue
    slot=${line%% *}
    [[ $line =~ $pci_ids ]] || continue
    vendor=${BASH_REMATCH[1]}
    ids=${BASH_REMATCH[0]}
    text=${line#*]: }
    text=${text%% "$ids"*}
    # The marketing name is the last bracketed part, when there is one:
    # "... Rembrandt [Radeon 680M]" is shown as "Radeon 680M".
    if [[ $text =~ $last_bracket ]]; then
      name=${BASH_REMATCH[1]}
    else
      name=${text#Intel Corporation }
      name=${name#NVIDIA Corporation }
      name=${name#Advanced Micro Devices, Inc. \[AMD/ATI\] }
    fi
    case $vendor in
      8086)
        [[ -n $intel_slot ]] || intel_slot=$slot
        found+=("Intel $name|$slot")
        ;;
      1002)
        [[ -n $amd_slot ]] || amd_slot=$slot
        [[ $text =~ $old_radeon ]] && amd_old=1
        found+=("AMD $name|$slot")
        ;;
      10de)
        if [[ -z $nvidia_slot ]]; then
          nvidia_slot=$slot
          nvidia_name=$text
        fi
        found+=("NVIDIA $name|$slot")
        ;;
      1af4 | 1234 | 15ad | 80ee | 1b36 | 1414 | 1013)
        vm=1
        found+=("$name (a virtual machine's graphics)|$slot")
        ;;
      *)
        found+=("$name|$slot")
        ;;
    esac
  done <<<"$listing"

  local generation=""
  [[ -n $nvidia_slot ]] && generation=$(nvidia_generation "$nvidia_name")

  # ---- What gpu.nix holds, and what to say about it ----
  local -a parts=() notes=()
  local igpu="" igpu_slot=""
  if [[ -n $intel_slot ]]; then
    igpu=intel
    igpu_slot=$intel_slot
  elif [[ -n $amd_slot ]]; then
    igpu=amdgpu
    igpu_slot=$amd_slot
  fi

  if [[ -n $intel_slot ]]; then
    parts+=("$(gpu_part intel)")
    ((laptop)) && parts+=("$(gpu_part intel-laptop)")
  fi
  if [[ -n $amd_slot ]]; then
    parts+=("$(gpu_part amd)")
    ((amd_old)) && parts+=("$(gpu_part amd-old)")
  fi

  if [[ -n $nvidia_slot ]]; then
    local base=nvidia
    case $generation in
      older) base=nvidia-older ;;
      unknown)
        notes+=("This NVIDIA card is newer than anything this tool knows, so it gets the settings for current cards. If it is a GeForce GTX 900 or 1000, use the 'older card' section of the guide instead.")
        ;;
      ancient)
        base=""
        notes+=("This NVIDIA card is too old for NVIDIA's driver to run Hyprland. NixOS uses the free 'nouveau' driver for it automatically. It works, but slowly.")
        ;;
    esac
    if [[ -n $base && -n $igpu ]]; then
      local part
      part=$(gpu_part "$base-two-gpus")
      part=${part//@IGPU@/$igpu}
      part=${part//@IGPU_BUS@/$(nixos_bus_id "$igpu_slot")}
      part=${part//@NVIDIA_BUS@/$(nixos_bus_id "$nvidia_slot")}
      if ((!laptop)); then
        # Switching the card off when idle is a laptop feature.
        part=$(grep -v 'powerManagement.finegrained' <<<"$part")
        notes+=("This looks like a desktop with built-in graphics as well as the NVIDIA card. If your screen is plugged into the NVIDIA card, you can switch the built-in graphics off in the BIOS and run 'hyprsimple-nixos gpu' again for a simpler setup.")
      fi
      parts+=("$part")
      notes+=("To run a program on the NVIDIA card, start it with:  nvidia-offload <program>")
    elif [[ -n $base ]]; then
      parts+=("$(gpu_part "$base")")
    fi
    if [[ -d $sysfs/module/nvidia ]]; then
      notes+=("The NVIDIA driver is already running. If you set it up yourself already, keep your settings and skip this file.")
    fi
  fi

  if [[ -n $intel_slot && -n $amd_slot && -z $nvidia_slot ]]; then
    notes+=("To run a program on the AMD card, start it with:  DRI_PRIME=1 <program>")
  fi
  if ((vm)) && [[ -z $intel_slot && -z $amd_slot && -z $nvidia_slot ]]; then
    notes+=("This is a virtual machine. Nothing to set here, but Hyprland needs 3D acceleration: turn it on in your virtual machine's display settings (VirtualBox, VMware, or virt-manager with 'OpenGL').")
  fi
  ((${#found[@]})) || notes+=("lspci did not find any graphics device.")

  # ---- gpu.nix ----
  local names="" entry
  for entry in "${found[@]}"; do names+="${names:+, }${entry%|*}"; done
  local module
  module=$(
    echo "# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'."
    echo "# Found: ${names:-no graphics device}."
    echo "# Guide: $GPU_GUIDE"
    echo "{ config, pkgs, ... }:"
    echo "{"
    if ((${#parts[@]} == 0)); then
      echo "  # Nothing needs setting for this computer."
    else
      local first=1
      for part in "${parts[@]}"; do
        ((first)) || echo
        first=0
        printf '%s\n' "$part"
      done
    fi
    echo "}"
  )

  if ((file_only)); then
    printf '%s\n' "$module"
    return 0
  fi

  say "${BOLD}Graphics in this computer:${NC}"
  if ((${#found[@]})); then
    for entry in "${found[@]}"; do
      say "  * ${entry%|*}   (at ${entry#*|})"
    done
  else
    say "  (none found)"
  fi
  if [[ -n $nvidia_slot ]]; then
    case $generation in
      current | unknown) say "  The NVIDIA card is a current one: GTX 1600, RTX 2000 or newer." ;;
      older) say "  The NVIDIA card is an older one: GTX 900 or GTX 1000 era." ;;
      ancient) say "  The NVIDIA card is from before the GTX 900 series." ;;
    esac
  fi
  ((laptop)) && say "  This is a laptop."
  say ""
  say "${BOLD}This is the gpu.nix file for it:${NC}"
  say "------------------------------------------------------------------------"
  printf '%s\n' "$module"
  say "------------------------------------------------------------------------"
  if ((${#notes[@]})); then
    say ""
    local n
    for n in "${notes[@]}"; do note "* $n"; done
  fi
  say ""
  if ((${#parts[@]} == 0)); then
    say "${BOLD}You do not need a gpu.nix.${NC} Go on with: hyprsimple-install"
    say "More about graphics: $GPU_GUIDE"
    return 0
  fi
  say "${BOLD}To use it:${NC}"
  say "  1. Save it:   hyprsimple-nixos gpu --file | sudo tee /etc/nixos/gpu.nix"
  say "  2. Open /etc/nixos/configuration.nix and add ./gpu.nix to its imports list."
  say "  3. Rebuild:   sudo nixos-rebuild switch"
  say "  4. Restart the computer."
  say "Every step explained: $GPU_GUIDE"
}

# ---- Dispatch --------------------------------------------------------------

command=${1:-}
shift || true
case $command in
  install) cmd_install "$@" ;;
  sync) cmd_sync "$@" ;;
  check-packages) cmd_check_packages "$@" ;;
  status) cmd_status "$@" ;;
  gpu) cmd_gpu "$@" ;;
  # For the systemctl stand-in that hyprsimple's migrations run.
  unpin-units) repair_user_units ;;
  -h | --help | help | "") usage ;;
  *)
    usage >&2
    exit 1
    ;;
esac
