#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/macde"
MARKER="$STATE_DIR/gnome-session-init.done"
WALLPAPER_FILE="/usr/share/backgrounds/macde-mountain.svg"
INSTALLER_DESKTOP_SOURCE="/usr/share/applications/install-debian.desktop"
INSTALLER_DESKTOP_NAME="Install MacDE GNOME.desktop"
EXTENSIONS="['dash-to-dock@micxgx.gmail.com']"
FAVORITES="['firefox-esr.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Settings.desktop', 'vlc.desktop', 'libreoffice-writer.desktop']"
GTK_THEME="Adwaita"
ICON_THEME="Adwaita"
CURSOR_THEME="Adwaita"

mkdir -p "$STATE_DIR"

pick_theme_fallback() {
  for theme in WhiteSur-Light WhiteSur-light WhiteSur WhiteSur-Dark; do
    if [ -d "/usr/share/themes/$theme" ]; then
      GTK_THEME="$theme"
      ICON_THEME="WhiteSur"
      CURSOR_THEME="WhiteSur-cursors"
      return 0
    fi
  done
}

ensure_installer_shortcut() {
  [ -f "$INSTALLER_DESKTOP_SOURCE" ] || return 0
  for desktop_dir in "$HOME/Desktop" "$HOME/Escritorio"; do
    mkdir -p "$desktop_dir"
    cp -f "$INSTALLER_DESKTOP_SOURCE" "$desktop_dir/$INSTALLER_DESKTOP_NAME"
    chmod +x "$desktop_dir/$INSTALLER_DESKTOP_NAME" || true
  done
}

set_if_possible() {
  schema="$1"
  key="$2"
  value="$3"

  if gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    gsettings set "$schema" "$key" "$value" >/dev/null 2>&1 || true
  fi
}

ensure_installer_shortcut
pick_theme_fallback

if [ -f "$MARKER" ]; then
  exit 0
fi

if command -v gsettings >/dev/null 2>&1; then
  set_if_possible org.gnome.shell enabled-extensions "$EXTENSIONS"
  set_if_possible org.gnome.shell favorite-apps "$FAVORITES"

  set_if_possible org.gnome.desktop.background picture-uri "'file://$WALLPAPER_FILE'"
  set_if_possible org.gnome.desktop.background picture-uri-dark "'file://$WALLPAPER_FILE'"
  set_if_possible org.gnome.desktop.wm.preferences button-layout "'close,minimize,maximize:'"

  set_if_possible org.gnome.desktop.interface gtk-theme "'$GTK_THEME'"
  set_if_possible org.gnome.desktop.interface icon-theme "'$ICON_THEME'"
  set_if_possible org.gnome.desktop.interface cursor-theme "'$CURSOR_THEME'"
  set_if_possible org.gnome.desktop.interface font-name "'Inter 10'"
  set_if_possible org.gnome.desktop.interface monospace-font-name "'JetBrains Mono 10'"
  set_if_possible org.gnome.desktop.interface enable-hot-corners "false"
  set_if_possible org.gnome.mutter dynamic-workspaces "true"

  set_if_possible org.gnome.shell.extensions.dash-to-dock dock-position "'BOTTOM'"
  set_if_possible org.gnome.shell.extensions.dash-to-dock dash-max-icon-size "48"
  set_if_possible org.gnome.shell.extensions.dash-to-dock extend-height "false"
  set_if_possible org.gnome.shell.extensions.dash-to-dock dock-fixed "false"
  set_if_possible org.gnome.shell.extensions.dash-to-dock autohide "true"
  set_if_possible org.gnome.shell.extensions.dash-to-dock intellihide "true"
  set_if_possible org.gnome.shell.extensions.dash-to-dock show-show-apps-button "false"
  set_if_possible org.gnome.shell.extensions.dash-to-dock transparency-mode "'DYNAMIC'"
  set_if_possible org.gnome.shell.extensions.dash-to-dock animation-time "0.15"
fi

touch "$MARKER"
