# Lean Conky Config, made to work on Wayland: Jason Xu's panel, from
# github.com/mysh264/lean-conky-config-wayland (programs.hyprsimple.conky).
#
# That repository packages itself, in nix/package.nix: the panel, and the
# `lean-conky-config` command, which copies it to ~/.config/lean-conky-config
# the first time and starts it with Conky and everything it runs on its PATH.
# This file only picks the version. For a newer one: put its commit in `rev`,
# and the hash `nix-prefetch-url --unpack` prints for its .tar.gz in `sha256`.
#
# builtins.fetchTarball (not pkgs.fetchFromGitHub) fetches it while the
# configuration is read, so its package.nix can be used without building
# anything first. It only happens when the setting is on.
{ pkgs }:
let
  rev = "44067a1bb8c56994b859914ad8c6593d56a12357";
  src = builtins.fetchTarball {
    url = "https://github.com/mysh264/lean-conky-config-wayland/archive/${rev}.tar.gz";
    sha256 = "1kpx0yfpd86zsvyh1cm9bmjj9ab8lxprq4hpsf7rc8dm8cyvb2li";
  };
in
pkgs.callPackage "${src}/nix/package.nix" { inherit src; }
