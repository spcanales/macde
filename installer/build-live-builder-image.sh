#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MACDE_LIVE_BUILDER_IMAGE:-macde/live-builder:bookworm-amd64}"
DOCKERFILE="${MACDE_LIVE_BUILDER_DOCKERFILE:-$ROOT_DIR/installer/docker/live-builder.Dockerfile}"
DOCKER_CONFIG="${DOCKER_CONFIG:-$ROOT_DIR/build/docker-config}"

mkdir -p "$DOCKER_CONFIG"
export DOCKER_CONFIG

if [ -z "${DOCKER_HOST:-}" ] && [ -S "$HOME/.colima/default/docker.sock" ]; then
  export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
fi

docker build \
  --platform linux/amd64 \
  -f "$DOCKERFILE" \
  -t "$IMAGE" \
  "$ROOT_DIR"

echo "Builder image lista: $IMAGE"
