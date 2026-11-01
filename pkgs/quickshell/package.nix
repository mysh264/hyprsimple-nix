{
  symlinkJoin,
  makeBinaryWrapper,
  quickshell,
  kdePackages,
}:

# Quickshell, which runs hyprsimple's bar, with Qt's extra image formats.
#
# Most of hyprsimple's wallpapers are webp, and Qt only reads webp through
# qtimageformats. Arch has it installed system wide; nixpkgs' quickshell does
# not carry it, so the theme and wallpaper pickers and the notification
# pictures came up empty for those wallpapers.
#
# The name matters too. hyprsimple finds its bar with `pgrep -f "qs -p ..."`,
# so the process must still be called qs. nixpkgs' bin/qs execs bin/quickshell
# under quickshell's full store path, which `pgrep` never matches, and
# hyprsimple-restart-bar.sh would start a second bar instead of restarting the
# first. Both names here go straight to bin/quickshell, whose own wrapper keeps
# the name it was started with.
symlinkJoin {
  name = "quickshell-${quickshell.version}";
  inherit (quickshell) version;
  paths = [ quickshell ];
  nativeBuildInputs = [ makeBinaryWrapper ];
  postBuild = ''
    for bin in qs quickshell; do
      rm "$out/bin/$bin"
      makeBinaryWrapper ${quickshell}/bin/quickshell $out/bin/$bin \
        --inherit-argv0 \
        --prefix QT_PLUGIN_PATH : ${kdePackages.qtimageformats}/${kdePackages.qtbase.qtPluginPrefix}
    done
  '';
  passthru.unwrapped = quickshell;
  meta = quickshell.meta // {
    description = "${quickshell.meta.description or "Quickshell"} (with webp support, for hyprsimple)";
  };
}
