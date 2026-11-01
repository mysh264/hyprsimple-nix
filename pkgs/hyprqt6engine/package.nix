{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  hyprlang,
  hyprutils,
  qtbase,
}:

# The Qt 6 platform theme hyprsimple selects in ~/.config/uwsm/env
# (QT_QPA_PLATFORMTHEME=hyprqt6engine). It is not in nixpkgs yet.
#
# Upstream ships its own expression in nix/default.nix. This follows it, with
# one change: the plugins go to Qt's standard plugin prefix (lib/qt-6/plugins)
# instead of lib/qt-6, so the QT_PLUGIN_PATH that `qt.enable` sets for the
# system profile finds them.
stdenv.mkDerivation (finalAttrs: {
  pname = "hyprqt6engine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "hyprwm";
    repo = "hyprqt6engine";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WSUMQmfVlpz31o2Tgfue0jnVRCeTrRi3Cy6s2/o8hzQ=";
  };

  patches = [
    # Upstream 9063e68, after v0.1.0: Qt 6.10 and newer only provide
    # Qt6::GuiPrivate when it is asked for by name, so the tag fails to
    # configure against current nixpkgs.
    ./0001-cmake-find-GuiPrivate.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    hyprlang
    hyprutils
    qtbase
  ];

  # A plugin library, loaded into other programs' Qt. Nothing to wrap.
  dontWrapQtApps = true;

  cmakeFlags = [
    (lib.cmakeFeature "PLUGINDIR" "${placeholder "out"}/${qtbase.qtPluginPrefix}")
  ];

  meta = {
    description = "Qt6 theme provider for Hyprland";
    homepage = "https://github.com/hyprwm/hyprqt6engine";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
