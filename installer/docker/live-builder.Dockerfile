FROM --platform=linux/amd64 debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
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
    xorriso && \
  rm -rf /var/lib/apt/lists/*

# Evita la purga de paquetes temporales de live-build.
RUN LB_PKG_FN=/usr/share/live/build/functions/packages.sh && \
  perl -0777 -i -pe "s@Remove_packages \\(\\)\\n\\{.*?\\n\\}\\n\\n@Remove_packages ()\\n{\\n\\treturn\\n}\\n\\n@s" "$LB_PKG_FN" && \
  grep -Eq "^[[:space:]]*Remove_packages \\(\\)" "$LB_PKG_FN" && \
  grep -Eq "^[[:space:]]*return$" "$LB_PKG_FN" && \
  ! grep -Eq "apt-get remove|aptitude purge|aptitude remove" "$LB_PKG_FN" && \
  for LB_STAGE in \
    /usr/lib/live/build/chroot_archives \
    /usr/lib/live/build/chroot_package-lists \
    /usr/lib/live/build/chroot_preseed \
    /usr/lib/live/build/installer_debian-installer; do \
      sed -i "s/^[[:space:]]*Remove_packages[[:space:]]*$/: # macde skip temp package removal/" "$LB_STAGE"; \
  done && \
  ! grep -REsn "^[[:space:]]*Remove_packages[[:space:]]*$" \
    /usr/lib/live/build/chroot_archives \
    /usr/lib/live/build/chroot_package-lists \
    /usr/lib/live/build/chroot_preseed \
    /usr/lib/live/build/installer_debian-installer

WORKDIR /work
