#!/usr/bin/env bash
# hyprsimple-nix: a stand-in for pacman, put on PATH only while hyprsimple runs
# its migrations (see hyprsimple-migrate.sh). Migrations are written for Arch
# and ask pacman whether a package is installed, and sometimes to install one.
#
# Queries are answered from the NixOS configuration: a package counts as
# installed when programs.hyprsimple provides it. Anything that would change
# the system is refused with an explanation, because on NixOS that change
# belongs in configuration.nix.

provided=/etc/hyprsimple/arch-packages
excluded=/etc/hyprsimple/arch-packages-excluded

installed() {
  grep -qxF -- "$1" "$provided" 2>/dev/null && ! grep -qxF -- "$1" "$excluded" 2>/dev/null
}

op=${1:-}
shift || true

names=()
for arg in "$@"; do
  [[ $arg == -* ]] || names+=("$arg")
done

case $op in
  -Q*)
    if ((${#names[@]} == 0)); then
      # A bare query lists what is installed.
      while IFS= read -r pkg; do
        installed "$pkg" || continue
        if [[ $op == *q* ]]; then echo "$pkg"; else echo "$pkg nixos"; fi
      done <"$provided"
      exit 0
    fi
    status=0
    for pkg in "${names[@]}"; do
      if installed "$pkg"; then
        if [[ $op == *i* ]]; then
          printf 'Name            : %s\nVersion         : provided by NixOS\n\n' "$pkg"
        elif [[ $op == *q* ]]; then
          echo "$pkg"
        else
          echo "$pkg nixos"
        fi
      else
        echo "error: package '$pkg' was not found" >&2
        status=1
      fi
    done
    exit "$status"
    ;;
  -S* | -R* | -U* | --sync | --remove | --upgrade)
    echo "hyprsimple-nix: on NixOS, packages come from your configuration, not pacman." >&2
    if ((${#names[@]})); then
      echo "hyprsimple asked for: ${names[*]}" >&2
      echo "If you want it, add it to environment.systemPackages and rebuild." >&2
    fi
    exit 1
    ;;
  *)
    echo "hyprsimple-nix: pacman is not available on NixOS." >&2
    exit 1
    ;;
esac
