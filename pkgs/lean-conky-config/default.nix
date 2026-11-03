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
  rev = "d7b53ded22473f323ac9088a2f392352b200b69e";
  src = builtins.fetchTarball {
    url = "https://github.com/mysh264/lean-conky-config-wayland/archive/${rev}.tar.gz";
    sha256 = "1gm3nj5j2s9k2qq2likplhsfgki1r17hixc9295ldkrl7v7yj7vk";
  };
in
pkgs.callPackage "${src}/nix/package.nix" { inherit src; }
