#!/usr/bin/env bash
# hyprsimple-nix: a stand-in for systemctl, put on PATH only while hyprsimple
# runs its migrations (see hyprsimple-migrate.sh). It runs the real systemctl.
# After a `systemctl --user enable`, it points the units NixOS ships back at
# /etc/systemd/user: enable links them from /nix/store into
# ~/.config/systemd/user, which keeps the version of that day running until a
# garbage collection removes it.

/run/current-system/sw/bin/systemctl "$@"
status=$?

user=0 enable=0
for arg in "$@"; do
  case $arg in
    --user) user=1 ;;
    enable | reenable) enable=1 ;;
  esac
done
if ((user && enable)); then
  @hyprsimpleNixos@ unpin-units >/dev/null 2>&1 || true
fi
exit "$status"
