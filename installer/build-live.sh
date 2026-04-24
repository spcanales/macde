#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
LIVE_TEMPLATE_DIR="$ROOT_DIR/live"
LIVE_WORK_DIR="$BUILD_DIR/live-work"
LIVE_CONFIG_PACKAGES_DIR="$LIVE_WORK_DIR/config/packages.chroot"
LIVE_VENDOR_DIR="$LIVE_WORK_DIR/config/includes.chroot/usr/share/macde/vendor"
PKG_DIR="$ROOT_DIR/pkg/macde-defaults"
OUTPUT_DEB="$BUILD_DIR/macde-defaults_all.deb"
IMAGE_OUTPUT_DIR="$BUILD_DIR/images/live"

MACDE_ARCH="${MACDE_ARCH:-amd64}"
MACDE_DIST="${MACDE_DIST:-bookworm}"
MACDE_SKIP_LB_BUILD="${MACDE_SKIP_LB_BUILD:-0}"
MACDE_PY3COMPILE_WORKAROUND="${MACDE_PY3COMPILE_WORKAROUND:-1}"
IMAGE_NAME="${IMAGE_NAME:-macde-live-$MACDE_ARCH}"
THEME_CACHE_DIR="${MACDE_THEME_CACHE_DIR:-$BUILD_DIR/theme-cache}"
LB_CACHE_DIR="${MACDE_LB_CACHE_DIR:-}"

WHITE_SUR_GTK_URL="${WHITE_SUR_GTK_URL:-https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/7ce45b4593cc5dc0073536e48761235c4acfe477.tar.gz}"
WHITE_SUR_ICONS_URL="${WHITE_SUR_ICONS_URL:-https://github.com/vinceliuice/WhiteSur-icon-theme/archive/bab5833b5cae200bccb786a2d3d6afa2201e7806.tar.gz}"
WHITE_SUR_CURSORS_URL="${WHITE_SUR_CURSORS_URL:-https://github.com/vinceliuice/WhiteSur-cursors/archive/e190baf618ed95ee217d2fd45589bd309b37672b.tar.gz}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Falta el comando requerido: $1" >&2
    exit 1
  fi
}

download_theme() {
  local url="$1"
  local output="$2"
  local cache_name
  cache_name="$(basename "$output")"
  local cache_file="$THEME_CACHE_DIR/$cache_name"

  mkdir -p "$THEME_CACHE_DIR"
  if [ -s "$cache_file" ]; then
    echo "==> Reutilizando $cache_name"
  else
    echo "==> Descargando $cache_name"
    curl -fsSL "$url" -o "$cache_file"
  fi

  cp "$cache_file" "$output"
}

apply_py3compile_workaround() {
  if [ "$MACDE_PY3COMPILE_WORKAROUND" != "1" ]; then
    return 0
  fi

  if [ ! -d chroot ]; then
    return 0
  fi

  echo "==> Aplicando workaround py3compile en chroot (emulacion qemu)"
  chroot chroot /bin/sh -eu -c '
dpkg-divert --local --rename --add --divert /usr/bin/py3compile.real /usr/bin/py3compile >/dev/null 2>&1 || true
cat > /usr/bin/py3compile <<'"'"'EOF'"'"'
#!/bin/sh
exit 0
EOF
chmod +x /usr/bin/py3compile
'
}

require_cmd curl
require_cmd dpkg-deb
require_cmd lb

rm -rf "$LIVE_WORK_DIR"
mkdir -p "$BUILD_DIR" "$LIVE_CONFIG_PACKAGES_DIR" "$LIVE_VENDOR_DIR" "$IMAGE_OUTPUT_DIR"

if [ -n "$LB_CACHE_DIR" ] && [ -d "$LB_CACHE_DIR" ]; then
  echo "==> Restaurando cache live-build"
  mkdir -p "$LIVE_WORK_DIR/cache"
  rsync -a --delete --no-devices --no-specials --exclude 'bootstrap/' "$LB_CACHE_DIR"/ "$LIVE_WORK_DIR/cache"/
fi

echo "==> Empaquetando macde-defaults"
rm -f "$OUTPUT_DEB"
dpkg-deb --build "$PKG_DIR" "$OUTPUT_DEB"

echo "==> Preparando arbol live-build"
cp -R "$LIVE_TEMPLATE_DIR"/. "$LIVE_WORK_DIR"/
cp "$OUTPUT_DEB" "$LIVE_CONFIG_PACKAGES_DIR"/

download_theme "$WHITE_SUR_GTK_URL" "$LIVE_VENDOR_DIR/whitesur-gtk.tar.gz"
download_theme "$WHITE_SUR_ICONS_URL" "$LIVE_VENDOR_DIR/whitesur-icons.tar.gz"
download_theme "$WHITE_SUR_CURSORS_URL" "$LIVE_VENDOR_DIR/whitesur-cursors.tar.gz"

cd "$LIVE_WORK_DIR"

echo "==> Configurando live-build"
lb config \
  --apt apt-get \
  --architecture "$MACDE_ARCH" \
  --distribution "$MACDE_DIST" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --cache true \
  --cache-packages true \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --firmware-chroot false \
  --firmware-binary false \
  --debian-installer none \
  --apt-recommends true \
  --image-name "$IMAGE_NAME" \
  --updates true \
  --bootappend-live "boot=live components live-media=removable live-media-timeout=30 username=macde hostname=macde-live user-fullname=MacDE Live locales=en_US.UTF-8 keyboard-layouts=us quiet splash"

if [ "$MACDE_SKIP_LB_BUILD" = "1" ]; then
  echo "Configuracion live-build generada en $LIVE_WORK_DIR"
  exit 0
fi

echo "==> Construyendo ISO live"
lb bootstrap
apply_py3compile_workaround
lb chroot
lb installer
lb binary
lb source

if [ -n "$LB_CACHE_DIR" ] && [ -d "$LIVE_WORK_DIR/cache" ]; then
  echo "==> Guardando cache live-build"
  mkdir -p "$LB_CACHE_DIR"
  rsync -a --delete --no-devices --no-specials --exclude 'bootstrap/' "$LIVE_WORK_DIR/cache"/ "$LB_CACHE_DIR"/
fi

ISO_PATH="$(find "$LIVE_WORK_DIR" -maxdepth 1 -name '*.iso' | head -n 1)"

if [ -z "$ISO_PATH" ]; then
  echo "No se encontro la ISO generada." >&2
  exit 1
fi

cp "$ISO_PATH" "$IMAGE_OUTPUT_DIR"/

echo
echo "Build live completado."
echo "Paquete local: $OUTPUT_DEB"
echo "ISO: $IMAGE_OUTPUT_DIR/$(basename "$ISO_PATH")"
