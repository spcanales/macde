#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
EXT_DIR="/usr/share/gnome-shell/extensions"
trap 'rm -rf "$WORKDIR"' EXIT INT TERM

install -d "$EXT_DIR"

fetch_and_install_zip() {
  uuid="$1"
  url="$2"
  sha256="$3"
  zip_path="$WORKDIR/$uuid.zip"
  dst="$EXT_DIR/$uuid"

  curl -fsSL "$url" -o "$zip_path"

  if command -v sha256sum >/dev/null 2>&1; then
    echo "$sha256  $zip_path" | sha256sum -c - >/dev/null
  else
    got="$(shasum -a 256 "$zip_path" | awk '{print $1}')"
    [ "$got" = "$sha256" ]
  fi

  rm -rf "$dst"
  mkdir -p "$dst"
  unzip -q "$zip_path" -d "$dst"

  if [ -d "$dst/schemas" ]; then
    glib-compile-schemas "$dst/schemas" || true
  fi
}

fetch_and_install_zip \
  "dash-to-dock@micxgx.gmail.com" \
  "https://extensions.gnome.org/download-extension/dash-to-dock@micxgx.gmail.com.shell-extension.zip?version_tag=42426" \
  "f79958611bc502b5f2661b0f0c3db013474e95200ecad2ce2c97b811ceebee47"

if [ "${MACDE_ENABLE_EXTRA_EXTENSIONS:-0}" = "1" ]; then
  fetch_and_install_zip \
    "blur-my-shell@aunetx" \
    "https://extensions.gnome.org/download-extension/blur-my-shell@aunetx.shell-extension.zip?version_tag=42627" \
    "1509e4f508b1d1050f070687247dd733a663e64a124529348f77bfaf7f84a9e5"

  fetch_and_install_zip \
    "just-perfection-desktop@just-perfection" \
    "https://extensions.gnome.org/download-extension/just-perfection-desktop@just-perfection.shell-extension.zip?version_tag=43626" \
    "2a65197afd22c1f6404837bac582ed50f75fa255dbb8ba31675b2d8c29bfce5a"
fi

echo "Extensiones GNOME instaladas."
