#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  -v "$ROOT_DIR:/work" \
  debian:bookworm \
  bash -lc '
    export DEBIAN_FRONTEND=noninteractive
    BUILD_ROOT=/tmp/macde-build

    apt-get update
    apt-get install -y \
      ca-certificates \
      curl \
      debootstrap \
      debhelper \
      dpkg-dev \
      dosfstools \
      gnupg \
      grub-efi-amd64-bin \
      grub-pc-bin \
      live-build \
      mtools \
      rsync \
      squashfs-tools \
      xorriso

    # Evita la purga de "temporary packages" de live-build.
    # En esta receta termina removiendo paquetes críticos del live (incluido user-setup).
    LB_PKG_FN=/usr/share/live/build/functions/packages.sh
    perl -0777 -i -pe "s@Remove_packages \\(\\)\\n\\{.*?\\n\\}\\n\\n@Remove_packages ()\\n{\\n\\treturn\\n}\\n\\n@s" "$LB_PKG_FN"

    awk "/^Remove_packages \\(\\)\$/{f=1} f{print} /^Install_packages \\(\\)\$/{exit}" "$LB_PKG_FN" > /tmp/remove_packages.fn
    grep -q "^[[:space:]]*return$" /tmp/remove_packages.fn
    if grep -q "apt-get remove\\|aptitude purge\\|aptitude remove" /tmp/remove_packages.fn; then
      echo "ERROR: Remove_packages no quedó neutralizado" >&2
      exit 1
    fi

    # Defensa adicional: evitar cualquier invocación directa a Remove_packages
    # desde scripts de etapas que disparan purga agresiva.
    for LB_STAGE in \
      /usr/lib/live/build/chroot_archives \
      /usr/lib/live/build/chroot_package-lists \
      /usr/lib/live/build/chroot_preseed \
      /usr/lib/live/build/installer_debian-installer
    do
      sed -i "s/^\\([[:space:]]*\\)Remove_packages\$/\\1: # macde skip temp package removal/" "$LB_STAGE"
    done

    if grep -Rsn "^[[:space:]]*Remove_packages\$" \
      /usr/lib/live/build/chroot_archives \
      /usr/lib/live/build/chroot_package-lists \
      /usr/lib/live/build/chroot_preseed \
      /usr/lib/live/build/installer_debian-installer >/dev/null
    then
      echo "ERROR: aún hay llamadas directas a Remove_packages en scripts de etapa" >&2
      exit 1
    fi

    rm -rf "$BUILD_ROOT"
    mkdir -p "$BUILD_ROOT" /work/build/images/live
    rsync -a --delete /work/ "$BUILD_ROOT"/

    cd "$BUILD_ROOT"
    ./installer/build-live.sh

    rsync -a "$BUILD_ROOT/build/macde-defaults_all.deb" /work/build/
    rsync -a "$BUILD_ROOT/build/images/live/" /work/build/images/live/
    chown -R "$LOCAL_UID:$LOCAL_GID" /work/build || true
  '
