#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
PKG_DIR="$ROOT_DIR/pkg/macde-defaults"
EXTRAS_DIR="$ROOT_DIR/installer/extras"
CONF_FILE="$BUILD_DIR/simple-cdd.conf"
OUTPUT_DEB="$BUILD_DIR/macde-defaults_all.deb"
MACDE_ARCH="${MACDE_ARCH:-amd64}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Falta el comando requerido: $1" >&2
    exit 1
  fi
}

require_cmd dpkg-deb
require_cmd build-simple-cdd

mkdir -p "$BUILD_DIR" "$EXTRAS_DIR"

echo "==> Empaquetando macde-defaults"
rm -f "$OUTPUT_DEB" "$EXTRAS_DIR/macde-defaults_all.deb"
dpkg-deb --build "$PKG_DIR" "$OUTPUT_DEB"
cp "$OUTPUT_DEB" "$EXTRAS_DIR/macde-defaults_all.deb"

cat > "$CONF_FILE" <<EOF
profiles="macde"
auto_profiles="macde"
dist="bookworm"
ARCHES="$MACDE_ARCH"
debian_mirror="http://deb.debian.org/debian"
security_mirror="http://security.debian.org/debian-security"
mirror_components="main contrib non-free non-free-firmware"
simple_cdd_dir="$ROOT_DIR/installer"
simple_cdd_temp="$BUILD_DIR/tmp"
simple_cdd_logs="$BUILD_DIR/logs"
simple_cdd_mirror="$BUILD_DIR/mirror"
BASEDIR="$BUILD_DIR/images"
EOF

echo "==> Ejecutando simple-cdd"
build-simple-cdd --conf "$CONF_FILE"

echo
echo "Build completado."
echo "Paquete local: $OUTPUT_DEB"
echo "Extras CD: $EXTRAS_DIR/macde-defaults_all.deb"
