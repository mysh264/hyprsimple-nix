#!/bin/sh
sec() { echo "## $1"; }
{
  sec bin; ls /usr/bin
  sec dbus-session-services; ls /usr/share/dbus-1/services 2>/dev/null
  sec systemd-user; ls /usr/lib/systemd/user /etc/systemd/user 2>/dev/null | grep -v ':$\|^$\|\.wants$\|\.requires$' | sort -u
  sec systemd-user-wants; for w in /usr/lib/systemd/user/*.wants /etc/systemd/user/*.wants; do [ -d "$w" ] || continue; for u in "$w"/*; do echo "$(basename "$w")/$(basename "$u")"; done; done
  sec autostart; ls /etc/xdg/autostart 2>/dev/null
  sec thumbnailers; ls /usr/share/thumbnailers 2>/dev/null
  sec portals; ls /usr/share/xdg-desktop-portal/portals /usr/share/xdg-desktop-portal 2>/dev/null
  sec gio-modules; ls /usr/lib/gio/modules 2>/dev/null
  sec qt6-plugins; (cd /usr/lib/qt6/plugins 2>/dev/null && find . -name '*.so' | sort)
  sec qt5-plugins; (cd /usr/lib/qt/plugins 2>/dev/null && find . -name '*.so' | sort)
  sec gsettings-schemas; ls /usr/share/glib-2.0/schemas 2>/dev/null
  sec applications; ls /usr/share/applications
  sec icons; ls /usr/share/icons
  sec themes; ls /usr/share/themes 2>/dev/null
  sec polkit-actions; ls /usr/share/polkit-1/actions 2>/dev/null
  sec fonts; fc-list : family 2>/dev/null | tr ',' '\n' | sort -u
  sec profile.d; ls /etc/profile.d /etc/environment.d /usr/lib/environment.d 2>/dev/null
  sec gdk-pixbuf-loaders; ls /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders 2>/dev/null
  sec gstreamer; ls /usr/lib/gstreamer-1.0 2>/dev/null
} > "${1:-/dev/stdout}"
