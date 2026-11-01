{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  curl,
  libnotify,
  alsa-lib,
  libpulseaudio,
  tzdata,
}:

# Prayer times and adhan notifications. hyprsimple installs it by default
# through its muslimtify plugin, which on Arch pulls it from the AUR. It is not
# in nixpkgs yet.
stdenv.mkDerivation (finalAttrs: {
  pname = "muslimtify";
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "muslimtify-org";
    repo = "muslimtify";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IfTEZNF7vVgmjmfFC7iOMs/tuhXsalZaE5QpNJR4UpA=";
  };

  patches = [
    # `muslimtify daemon install` writes a user unit that runs the binary it
    # finds first. Unpatched that is the running program, a /nix/store path
    # that garbage collection removes after the next upgrade.
    ./0001-nixos-stable-daemon-path.patch
  ];

  # One test asserts that the machine running it has a timezone configured in
  # /etc/localtime or /etc/timezone. The build sandbox has neither, and the
  # function's documented fallback (UTC, rc -1) is what it then returns, so
  # accept that case and keep the other location tests.
  postPatch = ''
    substituteInPlace tests/test_location.c \
      --replace-fail \
        "if (rc == 0 && buf[0] != '\\0') {" \
        "if ((rc == 0 && buf[0] != '\\0') || (rc == -1 && access(\"/etc/localtime\", F_OK) != 0 && access(\"/etc/timezone\", F_OK) != 0)) {"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    curl
    libnotify
  ];

  doCheck = true;
  # The prayer-time tests resolve real zones such as Asia/Jakarta, and the
  # build sandbox has no zoneinfo of its own.
  nativeCheckInputs = [ tzdata ];
  preCheck = ''
    export TZDIR=${tzdata}/share/zoneinfo
  '';

  # miniaudio, which plays the adhan, loads its audio backends with dlopen at
  # runtime. Nothing links them, so add them to the RUNPATH it searches.
  postFixup = ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        libpulseaudio
        alsa-lib
      ]
    } $out/bin/muslimtify
  '';

  meta = {
    description = "Prayer time notifications with adhan playback";
    homepage = "https://github.com/muslimtify-org/muslimtify";
    license = lib.licenses.mit;
    mainProgram = "muslimtify";
    platforms = lib.platforms.linux;
  };
})
