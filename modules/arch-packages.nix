# Every package in hyprsimple's packages.txt and aur-packages.txt, and what
# provides it on NixOS. Each entry has exactly one of:
#
#   packages = [ ... ];   installed into environment.systemPackages
#   fonts = [ ... ];      installed into fonts.packages
#   nixos = "...";        provided by the NixOS option named, which the module
#                         sets (a service, a program module, a replacement)
#
# `nix flake check` compares this file against the lists in the pinned
# hyprsimple version, so a package upstream adds cannot go unnoticed.
{
  pkgs,
  config,
  hyprsimplePkgs,
}:
{
  # Core Hyprland
  hyprland.nixos = "programs.hyprland";
  uwsm.nixos = "programs.hyprland.withUWSM";
  hyprpaper.packages = [ pkgs.hyprpaper ];
  hyprlock.packages = [ pkgs.hyprlock ];
  hypridle.packages = [ pkgs.hypridle ];
  hyprpicker.packages = [ pkgs.hyprpicker ];
  hyprpolkitagent.packages = [ pkgs.hyprpolkitagent ];
  hyprshot.packages = [ pkgs.hyprshot ];
  hyprsunset.packages = [ pkgs.hyprsunset ];
  xdg-desktop-portal-hyprland.nixos = "programs.hyprland";

  # UI / menu / status
  quickshell.packages = [ hyprsimplePkgs.quickshell ];
  ttf-material-symbols-variable.fonts = [ pkgs.material-symbols ];
  qt6-imageformats.packages = [ pkgs.kdePackages.qtimageformats ];
  zenity.packages = [ pkgs.zenity ];
  webp-pixbuf-loader.nixos = "programs.gdk-pixbuf.modulePackages";
  nwg-look.packages = [ pkgs.nwg-look ];
  gnome-themes-extra.packages = [ pkgs.gnome-themes-extra ];

  # Screenshots and screen tools
  grim.packages = [ pkgs.grim ];
  slurp.packages = [ pkgs.slurp ];
  wf-recorder.packages = [ pkgs.wf-recorder ];

  # System utilities
  networkmanager.nixos = "networking.networkmanager";
  cliphist.packages = [ pkgs.cliphist ];
  wl-clipboard.packages = [ pkgs.wl-clipboard ];
  playerctl.packages = [ pkgs.playerctl ];
  brightnessctl.packages = [ pkgs.brightnessctl ];
  bluez.nixos = "hardware.bluetooth";
  bluez-utils.nixos = "hardware.bluetooth";
  libnotify.packages = [ pkgs.libnotify ];
  nautilus.packages = [ pkgs.nautilus ];
  gvfs.nixos = "services.gvfs";
  unzip.packages = [ pkgs.unzip ];
  libusb.packages = [ pkgs.libusb1 ];
  zip.packages = [ pkgs.zip ];
  cpupower.packages = [ config.boot.kernelPackages.cpupower ];
  btop.packages = [ pkgs.btop ];
  power-profiles-daemon.nixos = "services.power-profiles-daemon";
  upower.nixos = "services.upower";
  qt5-wayland.packages = [ pkgs.libsForQt5.qtwayland ];
  qt6-wayland.packages = [ pkgs.kdePackages.qtwayland ];
  kvantum.packages = [
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.kdePackages.qtstyleplugin-kvantum
  ];

  # Networking (the hotspot script)
  dnsmasq.packages = [ pkgs.dnsmasq ];
  iptables.packages = [ pkgs.iptables ];
  hostapd.packages = [ pkgs.hostapd ];
  haveged.packages = [ pkgs.haveged ];
  iw.packages = [ pkgs.iw ];
  ufw.nixos = "networking.firewall";

  # Applications
  ghostty.packages = [ pkgs.ghostty ];
  neovim.packages = [ pkgs.neovim ];
  firefox.packages = [ pkgs.firefox ];

  # Audio and video
  pipewire.nixos = "services.pipewire";
  pipewire-alsa.nixos = "services.pipewire.alsa";
  pipewire-audio.nixos = "services.pipewire";
  pipewire-pulse.nixos = "services.pipewire.pulse";
  wireplumber.nixos = "services.pipewire.wireplumber";
  alsa-utils.packages = [ pkgs.alsa-utils ];
  ffmpeg.packages = [ pkgs.ffmpeg ];
  swayimg.packages = [ pkgs.swayimg ];

  papirus-icon-theme.packages = [ pkgs.papirus-icon-theme ];

  # CLI tools
  fzf.packages = [ pkgs.fzf ];
  bat.packages = [ pkgs.bat ];
  vi.packages = [ pkgs.nvi ];
  less.packages = [ pkgs.less ];
  zoxide.packages = [ pkgs.zoxide ];
  yazi.packages = [ pkgs.yazi ];
  starship.packages = [ pkgs.starship ];
  fastfetch.packages = [ pkgs.fastfetch ];
  inxi.packages = [ pkgs.inxi ];
  lsd.packages = [ pkgs.lsd ];
  git.packages = [ pkgs.git ];
  jq.packages = [ pkgs.jq ];
  bash-completion.nixos = "programs.bash.completion";
  ripgrep.packages = [ pkgs.ripgrep ];
  lazygit.packages = [ pkgs.lazygit ];

  # Fonts
  ttf-jetbrains-mono-nerd.fonts = [ pkgs.nerd-fonts.jetbrains-mono ];
  ttf-iosevka-nerd.fonts = [ pkgs.nerd-fonts.iosevka ];
  noto-fonts-cjk.fonts = [
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
  ];
  noto-fonts-emoji.fonts = [ pkgs.noto-fonts-color-emoji ];

  # From the AUR on Arch
  yaru-icon-theme.packages = [ pkgs.yaru-theme ];
  wl-mirror.packages = [ pkgs.wl-mirror ];
  wl-screenrec-git.packages = [ pkgs.wl-screenrec ];
  imagemagick.packages = [ pkgs.imagemagick ];
  hyprshutdown.packages = [ pkgs.hyprshutdown ];
  hyprqt6engine.packages = [ hyprsimplePkgs.hyprqt6engine ];
  noise-suppression-for-voice.packages = [ pkgs.rnnoise-plugin ];
}
