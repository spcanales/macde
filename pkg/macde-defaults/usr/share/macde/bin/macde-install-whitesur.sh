#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root." >&2
  exit 1
fi

INSTALL_GDM=0
for arg in "$@"; do
  case "$arg" in
    --gdm) INSTALL_GDM=1 ;;
    --system) : ;;
  esac
done

WORKDIR="$(mktemp -d)"
VENDOR_DIR="/usr/share/macde/vendor"
trap 'rm -rf "$WORKDIR"' EXIT INT TERM

WHITE_SUR_GTK_URL="${WHITE_SUR_GTK_URL:-https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/7ce45b4593cc5dc0073536e48761235c4acfe477.tar.gz}"
WHITE_SUR_ICONS_URL="${WHITE_SUR_ICONS_URL:-https://github.com/vinceliuice/WhiteSur-icon-theme/archive/bab5833b5cae200bccb786a2d3d6afa2201e7806.tar.gz}"
WHITE_SUR_CURSORS_URL="${WHITE_SUR_CURSORS_URL:-https://github.com/vinceliuice/WhiteSur-cursors/archive/e190baf618ed95ee217d2fd45589bd309b37672b.tar.gz}"

extract_archive() {
  archive="$1"
  dest="$2"
  mkdir -p "$dest"
  tar -xzf "$archive" -C "$dest"
}

download_and_extract() {
  name="$1"
  url="$2"
  dest="$3"

  archive="$WORKDIR/$name.tar.gz"
  curl -fsSL "$url" -o "$archive"
  extract_archive "$archive" "$dest"
}

extract_or_download() {
  local_archive="$1"
  url="$2"
  dest="$3"

  if [ -f "$local_archive" ]; then
    extract_archive "$local_archive" "$dest"
  else
    download_and_extract "$(basename "$local_archive" .tar.gz)" "$url" "$dest"
  fi
}

extract_or_download "$VENDOR_DIR/whitesur-gtk.tar.gz" "$WHITE_SUR_GTK_URL" "$WORKDIR"
extract_or_download "$VENDOR_DIR/whitesur-icons.tar.gz" "$WHITE_SUR_ICONS_URL" "$WORKDIR"
extract_or_download "$VENDOR_DIR/whitesur-cursors.tar.gz" "$WHITE_SUR_CURSORS_URL" "$WORKDIR"

install -d /usr/share/backgrounds
if [ -f /usr/share/macde/wallpapers/mountain.svg ]; then
  cp -f /usr/share/macde/wallpapers/mountain.svg /usr/share/backgrounds/macde-mountain.svg
fi

cd "$WORKDIR"/WhiteSur-gtk-theme-*
./install.sh -d /usr/share/themes -c light -N stable --shell --silent-mode

if [ "$INSTALL_GDM" = "1" ] && [ -x ./tweaks.sh ]; then
  ./tweaks.sh -g -b /usr/share/backgrounds/macde-mountain.svg --silent-mode || true
fi

cd "$WORKDIR"/WhiteSur-icon-theme-*
./install.sh -d /usr/share/icons -a

cd "$WORKDIR"/WhiteSur-cursors-*
./install.sh

if command -v glib-compile-schemas >/dev/null 2>&1; then
  glib-compile-schemas /usr/share/glib-2.0/schemas || true
fi

echo "WhiteSur GTK/Shell/Icons/Cursors instalado."
