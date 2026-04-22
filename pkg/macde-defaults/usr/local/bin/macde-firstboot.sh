#!/bin/sh
set -eu

BASE_MARKER="$HOME/.local/state/macde/base-layout.done"
WHITESUR_MARKER="$HOME/.local/state/macde/whitesur.done"
WALLPAPER_FILE="/usr/share/macde/wallpapers/sunrise.svg"
WHITESUR_THEME_ID="com.github.vinceliuice.WhiteSur"
GTK3_DIR="$HOME/.config/gtk-3.0"
GTK4_DIR="$HOME/.config/gtk-4.0"
KVANTUM_DIR="$HOME/.config/Kvantum"

mkdir -p "$(dirname "$BASE_MARKER")"

BASE_PENDING=0
WHITESUR_PENDING=0

if [ ! -f "$BASE_MARKER" ]; then
  BASE_PENDING=1
fi

if [ -d "/usr/share/plasma/look-and-feel/$WHITESUR_THEME_ID" ] && [ ! -f "$WHITESUR_MARKER" ]; then
  WHITESUR_PENDING=1
fi

if [ "$BASE_PENDING" -eq 0 ] && [ "$WHITESUR_PENDING" -eq 0 ]; then
  exit 0
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
  KWRITECONFIG="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  KWRITECONFIG="kwriteconfig5"
else
  KWRITECONFIG=""
fi

if command -v qdbus >/dev/null 2>&1; then
  QDBUS_CMD="qdbus"
elif command -v qdbus-qt5 >/dev/null 2>&1; then
  QDBUS_CMD="qdbus-qt5"
else
  QDBUS_CMD=""
fi

layout_applied() {
  [ -n "$QDBUS_CMD" ] || return 1
  "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.dumpCurrentLayoutJS 2>/dev/null \
    | grep -q "org.kde.plasma.appmenu"
}

if [ "$BASE_PENDING" -eq 1 ]; then
  if [ -n "$KWRITECONFIG" ]; then
    "$KWRITECONFIG" --file kdeglobals --group KDE --key SingleClick false || true
    "$KWRITECONFIG" --file kdeglobals --group General --key ColorScheme BreezeLight || true
    "$KWRITECONFIG" --file kdeglobals --group General --key TerminalApplication konsole || true
    "$KWRITECONFIG" --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" || true
    "$KWRITECONFIG" --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA || true
    "$KWRITECONFIG" --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "" || true
  fi

  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$WALLPAPER_FILE" || true
  fi

  if [ -n "$QDBUS_CMD" ] && [ -f "/usr/share/macde/layouts/macde-layout.js" ]; then
    for _try in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      if "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.dumpCurrentLayoutJS >/dev/null 2>&1; then
        "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat /usr/share/macde/layouts/macde-layout.js)" >/dev/null 2>&1 || true
        if layout_applied; then
          break
        fi
      fi
      sleep 2
    done
  fi

  if layout_applied || [ -z "$QDBUS_CMD" ]; then
    touch "$BASE_MARKER"
  fi
fi

if [ "$WHITESUR_PENDING" -eq 1 ]; then
  if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
    plasma-apply-lookandfeel -a "$WHITESUR_THEME_ID" || true
  elif command -v lookandfeeltool >/dev/null 2>&1; then
    lookandfeeltool -a "$WHITESUR_THEME_ID" || true
  fi

  if [ -n "$KWRITECONFIG" ]; then
    "$KWRITECONFIG" --file kdeglobals --group Icons --key Theme WhiteSur || true
    "$KWRITECONFIG" --file kdeglobals --group KDE --key widgetStyle kvantum || true
    "$KWRITECONFIG" --file kcminputrc --group Mouse --key cursorTheme WhiteSur-cursors || true
  fi

  mkdir -p "$KVANTUM_DIR"

  if [ -d "/usr/share/themes/WhiteSur-Light" ]; then
    mkdir -p "$GTK3_DIR" "$GTK4_DIR"

    cat > "$GTK3_DIR/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=WhiteSur-Light
gtk-icon-theme-name=WhiteSur
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Noto Sans 10
EOF

    cat > "$GTK4_DIR/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=WhiteSur-Light
gtk-icon-theme-name=WhiteSur
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Noto Sans 10
EOF
  fi

  cat > "$KVANTUM_DIR/kvantum.kvconfig" <<'EOF'
[General]
theme=WhiteSur
EOF

  touch "$WHITESUR_MARKER"
fi
