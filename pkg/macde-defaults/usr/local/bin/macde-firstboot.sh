#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/macde"
MARKER="$STATE_DIR/gnome-session-init.done"
WALLPAPER_FILE="/usr/share/backgrounds/macde-mountain.svg"
INSTALLER_DESKTOP_SOURCE="/usr/share/applications/install-debian.desktop"
INSTALLER_DESKTOP_NAME="Install MacDE.desktop"
EXTENSIONS="['dash-to-dock@micxgx.gmail.com', 'ding@rastersoft.com']"
FAVORITES="['firefox-esr.desktop', 'org.gnome.Notes.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Settings.desktop', 'vlc.desktop', 'libreoffice-writer.desktop']"
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

resolve_desktop_dir() {
  desktop_dir=""
  if command -v xdg-user-dir >/dev/null 2>&1; then
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
  fi

  case "$desktop_dir" in
    ""|"$HOME")
      if [ -d "$HOME/Desktop" ] || [ ! -e "$HOME/Desktop" ]; then
        desktop_dir="$HOME/Desktop"
      else
        desktop_dir="$HOME/Escritorio"
      fi
      ;;
  esac

  printf '%s\n' "$desktop_dir"
}

mark_trusted_desktop_file() {
  desktop_file="$1"
  [ -f "$desktop_file" ] || return 0
  chmod +x "$desktop_file" || true
  if command -v gio >/dev/null 2>&1; then
    gio set "$desktop_file" metadata::trusted true >/dev/null 2>&1 || true
  fi
}

remove_duplicate_installer_shortcuts() {
  desktop_dir="$1"
  canonical="$desktop_dir/$INSTALLER_DESKTOP_NAME"
  [ -d "$desktop_dir" ] || return 0

  for candidate in "$desktop_dir"/*.desktop; do
    [ -e "$candidate" ] || continue
    [ "$candidate" = "$canonical" ] && continue
    if grep -q '^Exec=install-debian' "$candidate" >/dev/null 2>&1; then
      rm -f "$candidate"
    fi
  done
}

ensure_installer_shortcut() {
  [ -f "$INSTALLER_DESKTOP_SOURCE" ] || return 0
  desktop_dir="$(resolve_desktop_dir)"
  mkdir -p "$desktop_dir"
  cp -f "$INSTALLER_DESKTOP_SOURCE" "$desktop_dir/$INSTALLER_DESKTOP_NAME"
  mark_trusted_desktop_file "$desktop_dir/$INSTALLER_DESKTOP_NAME"
  remove_duplicate_installer_shortcuts "$desktop_dir"
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
  set_if_possible org.gnome.shell.extensions.ding icon-size "'small'"
fi

touch "$MARKER"
