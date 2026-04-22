#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker run --rm \
  --platform linux/amd64 \
  -e LOCAL_UID="$(id -u)" \
  -e LOCAL_GID="$(id -g)" \
  -v "$ROOT_DIR:/work" \
  -w /work \
  debian:bookworm \
  bash -lc '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y \
      ca-certificates \
      curl \
      debhelper \
      dpkg-dev \
      gnupg \
      rsync \
      simple-cdd \
      xorriso
    ./installer/build-netinstall.sh
    chown -R "$LOCAL_UID:$LOCAL_GID" /work/build || true
  '
