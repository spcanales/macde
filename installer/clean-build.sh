#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
KEEP_ISO=1

if [ "${1:-}" = "--all" ]; then
  KEEP_ISO=0
fi

rm -rf "$BUILD_DIR/live-work"
rm -f "$BUILD_DIR/macde-defaults_all.deb"

if [ "$KEEP_ISO" -eq 0 ]; then
  rm -rf "$BUILD_DIR/images"
fi

mkdir -p "$BUILD_DIR/images/live"

echo "Limpieza completada."
if [ "$KEEP_ISO" -eq 1 ]; then
  echo "Se conservaron las ISOs en $BUILD_DIR/images/live"
else
  echo "Se eliminaron tambien las ISOs de $BUILD_DIR/images/live"
fi

du -sh "$BUILD_DIR" "$BUILD_DIR/images" 2>/dev/null || true
