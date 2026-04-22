#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDER_IMAGE="${MACDE_LIVE_BUILDER_IMAGE:-macde/live-builder:bookworm-amd64}"
DOCKER_CACHE_DIR="$ROOT_DIR/build/docker-cache"
APT_CACHE_DIR="$DOCKER_CACHE_DIR/apt-cache"
APT_LISTS_DIR="$DOCKER_CACHE_DIR/apt-lists"
LB_CACHE_DIR="$DOCKER_CACHE_DIR/live-build-cache"
THEME_CACHE_DIR="$DOCKER_CACHE_DIR/theme-cache"
DOCKER_CONFIG="${DOCKER_CONFIG:-$ROOT_DIR/build/docker-config}"

mkdir -p "$APT_CACHE_DIR" "$APT_LISTS_DIR" "$LB_CACHE_DIR" "$THEME_CACHE_DIR" "$DOCKER_CONFIG"
export DOCKER_CONFIG

if [ "${MACDE_DOCKER_REBUILD:-0}" = "1" ] || ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
  "$ROOT_DIR/installer/build-live-builder-image.sh"
fi

docker run --rm \
  --privileged \
  --platform linux/amd64 \
  -e LOCAL_UID="$(id -u)" \
  -e LOCAL_GID="$(id -g)" \
  -e MACDE_ARCH="${MACDE_ARCH:-amd64}" \
  -e MACDE_DIST="${MACDE_DIST:-bookworm}" \
  -e MACDE_SKIP_LB_BUILD="${MACDE_SKIP_LB_BUILD:-0}" \
  -e IMAGE_NAME="${IMAGE_NAME:-}" \
  -e WHITE_SUR_KDE_URL="${WHITE_SUR_KDE_URL:-}" \
  -e WHITE_SUR_ICONS_URL="${WHITE_SUR_ICONS_URL:-}" \
  -e WHITE_SUR_CURSORS_URL="${WHITE_SUR_CURSORS_URL:-}" \
  -e WHITE_SUR_GTK_URL="${WHITE_SUR_GTK_URL:-}" \
  -e MACDE_LB_CACHE_DIR=/cache/live-build \
  -e MACDE_THEME_CACHE_DIR=/cache/theme \
  -v "$ROOT_DIR:/work" \
  -v "$APT_CACHE_DIR:/var/cache/apt" \
  -v "$APT_LISTS_DIR:/var/lib/apt/lists" \
  -v "$LB_CACHE_DIR:/cache/live-build" \
  -v "$THEME_CACHE_DIR:/cache/theme" \
  "$BUILDER_IMAGE" \
  bash -lc '
    BUILD_ROOT=/tmp/macde-build

    rm -rf "$BUILD_ROOT"
    mkdir -p "$BUILD_ROOT" /work/build/images/live
    rsync -a --delete /work/ "$BUILD_ROOT"/

    cd "$BUILD_ROOT"
    ./installer/build-live.sh

    rsync -a "$BUILD_ROOT/build/macde-defaults_all.deb" /work/build/
    rsync -a "$BUILD_ROOT/build/images/live/" /work/build/images/live/
    chown -R "$LOCAL_UID:$LOCAL_GID" /work/build || true
  '
