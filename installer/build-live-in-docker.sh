#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDER_IMAGE="${MACDE_LIVE_BUILDER_IMAGE:-macde/live-builder:bookworm-amd64}"
CONTAINER_NAME="${MACDE_LIVE_BUILDER_CONTAINER:-macde-live-builder-amd64}"
PERSISTENT_CONTAINER="${MACDE_DOCKER_PERSISTENT:-1}"
BUILD_ROOT_IN_CONTAINER="${MACDE_BUILD_ROOT:-/var/cache/macde/workdir/macde-build}"
DOCKER_CACHE_DIR="$ROOT_DIR/build/docker-cache"
APT_CACHE_DIR="$DOCKER_CACHE_DIR/apt-cache"
APT_LISTS_DIR="$DOCKER_CACHE_DIR/apt-lists"
LB_CACHE_DIR="$DOCKER_CACHE_DIR/live-build-cache"
THEME_CACHE_DIR="$DOCKER_CACHE_DIR/theme-cache"
WORKDIR_CACHE_DIR="$DOCKER_CACHE_DIR/workdir"
DOCKER_CONFIG="${DOCKER_CONFIG:-$ROOT_DIR/build/docker-config}"

mkdir -p \
  "$APT_CACHE_DIR" \
  "$APT_LISTS_DIR" \
  "$LB_CACHE_DIR" \
  "$THEME_CACHE_DIR" \
  "$WORKDIR_CACHE_DIR" \
  "$DOCKER_CONFIG" \
  "$ROOT_DIR/build/images/live"
export DOCKER_CONFIG

if [ -z "${DOCKER_HOST:-}" ] && [ -S "$HOME/.colima/default/docker.sock" ]; then
  export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
fi

if [ "${MACDE_DOCKER_REBUILD:-0}" = "1" ] || ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
  "$ROOT_DIR/installer/build-live-builder-image.sh"
fi

if [ "${MACDE_DOCKER_RECREATE:-0}" = "1" ]; then
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

build_cmd='
  BUILD_ROOT="${MACDE_BUILD_ROOT:-/var/cache/macde/workdir/macde-build}"
  mkdir -p "$BUILD_ROOT" /work/build/images/live
  rsync -a --delete /work/ "$BUILD_ROOT"/

  cd "$BUILD_ROOT"
  ./installer/build-live.sh

  rsync -a "$BUILD_ROOT/build/macde-defaults_all.deb" /work/build/
  rsync -a "$BUILD_ROOT/build/images/live/" /work/build/images/live/
  chown -R "$LOCAL_UID:$LOCAL_GID" /work/build || true
'

if [ "$PERSISTENT_CONTAINER" = "1" ]; then
  if ! docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    docker create \
      --name "$CONTAINER_NAME" \
      --privileged \
      --platform linux/amd64 \
      -e MACDE_LB_CACHE_DIR=/cache/live-build \
      -e MACDE_THEME_CACHE_DIR=/cache/theme \
      -e MACDE_BUILD_ROOT="$BUILD_ROOT_IN_CONTAINER" \
      -v "$ROOT_DIR:/work" \
      -v "$APT_CACHE_DIR:/var/cache/apt" \
      -v "$APT_LISTS_DIR:/var/lib/apt/lists" \
      -v "$LB_CACHE_DIR:/cache/live-build" \
      -v "$THEME_CACHE_DIR:/cache/theme" \
      -v "$WORKDIR_CACHE_DIR:/cache/workdir" \
      "$BUILDER_IMAGE" \
      sleep infinity >/dev/null
  fi

  if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
    docker start "$CONTAINER_NAME" >/dev/null
  fi

  echo "==> Contenedor persistente: $CONTAINER_NAME"
  docker exec \
    -e LOCAL_UID="$(id -u)" \
    -e LOCAL_GID="$(id -g)" \
    -e MACDE_ARCH="${MACDE_ARCH:-amd64}" \
    -e MACDE_DIST="${MACDE_DIST:-bookworm}" \
    -e MACDE_SKIP_LB_BUILD="${MACDE_SKIP_LB_BUILD:-0}" \
    -e IMAGE_NAME="${IMAGE_NAME:-}" \
    -e WHITE_SUR_ICONS_URL="${WHITE_SUR_ICONS_URL:-}" \
    -e WHITE_SUR_CURSORS_URL="${WHITE_SUR_CURSORS_URL:-}" \
    -e WHITE_SUR_GTK_URL="${WHITE_SUR_GTK_URL:-}" \
    -e MACDE_LB_CACHE_DIR=/cache/live-build \
    -e MACDE_THEME_CACHE_DIR=/cache/theme \
    -e MACDE_BUILD_ROOT="$BUILD_ROOT_IN_CONTAINER" \
    "$CONTAINER_NAME" \
    bash -lc "$build_cmd"
else
  docker run --rm \
    --privileged \
    --platform linux/amd64 \
    -e LOCAL_UID="$(id -u)" \
    -e LOCAL_GID="$(id -g)" \
    -e MACDE_ARCH="${MACDE_ARCH:-amd64}" \
    -e MACDE_DIST="${MACDE_DIST:-bookworm}" \
    -e MACDE_SKIP_LB_BUILD="${MACDE_SKIP_LB_BUILD:-0}" \
    -e IMAGE_NAME="${IMAGE_NAME:-}" \
    -e WHITE_SUR_ICONS_URL="${WHITE_SUR_ICONS_URL:-}" \
    -e WHITE_SUR_CURSORS_URL="${WHITE_SUR_CURSORS_URL:-}" \
    -e WHITE_SUR_GTK_URL="${WHITE_SUR_GTK_URL:-}" \
    -e MACDE_LB_CACHE_DIR=/cache/live-build \
    -e MACDE_THEME_CACHE_DIR=/cache/theme \
    -e MACDE_BUILD_ROOT="$BUILD_ROOT_IN_CONTAINER" \
    -v "$ROOT_DIR:/work" \
    -v "$APT_CACHE_DIR:/var/cache/apt" \
    -v "$APT_LISTS_DIR:/var/lib/apt/lists" \
    -v "$LB_CACHE_DIR:/cache/live-build" \
    -v "$THEME_CACHE_DIR:/cache/theme" \
    -v "$WORKDIR_CACHE_DIR:/cache/workdir" \
    "$BUILDER_IMAGE" \
    bash -lc "$build_cmd"
fi
