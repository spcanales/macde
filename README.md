# MacDE Live ISO (GNOME)

ISO live `amd64` basada en Debian 12 (Bookworm) para MacBook Intel 2011-2012, con GNOME (Wayland por defecto), UX estilo macOS, Calamares y build reproducible.

## Estado actual

- Escritorio: GNOME (`gdm3`, `gnome-shell`, `gnome-control-center`, `task-gnome-desktop`).
- Look base estable: Adwaita + dock inferior (`dash-to-dock`) + top bar limpia + wallpaper Mountain.
- WhiteSur: opcional (no forzado en build para evitar inestabilidad).
- Apps incluidas: Firefox, VLC, LibreOffice, Synaptic.
- Hardware Mac Intel: Broadcom STA + firmware, `hid_apple fnmode=2`, `tlp`, `mbpfan`, `fwupd`, touchpad libinput.
- Instalador: Calamares con branding MacDE GNOME y acceso directo en el escritorio live.

## Estructura

```text
installer/
  build-live.sh
  build-live-in-docker.sh
  build-live-builder-image.sh
  docker/live-builder.Dockerfile
  clean-build.sh
live/config/
  package-lists/macde.list.chroot
  hooks/live/010-install-whitesur.hook.chroot
  hooks/live/999-restore-py3compile.hook.chroot
  includes.chroot/etc/calamares/branding/macde/*
pkg/macde-defaults/
  DEBIAN/{control,postinst}
  etc/dconf/{profile/user,db/local.d/00-macde}
  etc/modprobe.d/hid_apple.conf
  etc/X11/xorg.conf.d/40-macbook-touchpad.conf
  usr/local/bin/{macde-firstboot.sh,macde-postinstall,macde-drivers}
  usr/share/macde/bin/{macde-install-whitesur.sh,macde-install-gnome-extensions.sh}
```

## Build rápido (macOS + Docker persistente)

```bash
cd /ruta/a/macde
./installer/build-live-builder-image.sh
./installer/build-live-in-docker.sh
```

Salida:

- `build/macde-defaults_all.deb`
- `build/images/live/macde-live-amd64-amd64.hybrid.iso`

El contenedor `linux/amd64` es persistente por defecto (`macde-live-builder-amd64`) y reutiliza cachés en `build/docker-cache/` (`apt-cache`, `apt-lists`, `live-build-cache`, `theme-cache`, `workdir`).

## Variables útiles

```bash
# reconstruir imagen builder
MACDE_DOCKER_REBUILD=1 ./installer/build-live-in-docker.sh

# recrear contenedor persistente
MACDE_DOCKER_RECREATE=1 ./installer/build-live-in-docker.sh

# modo efímero (sin contenedor persistente)
MACDE_DOCKER_PERSISTENT=0 ./installer/build-live-in-docker.sh

# validar config sin build completo
MACDE_SKIP_LB_BUILD=1 ./installer/build-live-in-docker.sh

# habilitar WhiteSur durante build/postinstall (opcional)
MACDE_ENABLE_WHITESUR=1 ./installer/build-live-in-docker.sh
```

## Boot test en QEMU (copy/paste)

```bash
ISO="/Users/sergio/Downloads/linux/macde/build/images/live/macde-live-amd64-amd64.hybrid.iso"; VM_DIR="$HOME/.cache/macde-qemu"; DISK="$VM_DIR/macde-live-test.qcow2"; FW=""; for p in /opt/homebrew/share/qemu/edk2-x86_64-code.fd /usr/local/share/qemu/edk2-x86_64-code.fd /opt/homebrew/share/qemu/OVMF_CODE.fd /usr/local/share/qemu/OVMF_CODE.fd; do [ -f "$p" ] && FW="$p" && break; done; mkdir -p "$VM_DIR"; [ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 64G; if [ -n "$FW" ]; then qemu-system-x86_64 -machine q35,accel=tcg -cpu max -smp 4 -m 8192 -bios "$FW" -boot order=d -cdrom "$ISO" -drive if=virtio,format=qcow2,file="$DISK" -device qemu-xhci -device usb-kbd -device usb-tablet -nic user,model=virtio-net-pci -vga std -display cocoa -audiodev coreaudio,id=audio0 -device ich9-intel-hda -device hda-output,audiodev=audio0; else qemu-system-x86_64 -machine q35,accel=tcg -cpu max -smp 4 -m 8192 -boot order=d -cdrom "$ISO" -drive if=virtio,format=qcow2,file="$DISK" -device qemu-xhci -device usb-kbd -device usb-tablet -nic user,model=virtio-net-pci -vga std -display cocoa -audiodev coreaudio,id=audio0 -device ich9-intel-hda -device hda-output,audiodev=audio0; fi
```

## Configuración GNOME aplicada

- Sistema (`dconf`): `pkg/macde-defaults/etc/dconf/db/local.d/00-macde`
- Sesión usuario (primer login): `pkg/macde-defaults/usr/local/bin/macde-firstboot.sh`
- Dock: abajo, autohide/intellihide, favoritos con Firefox/VLC/LibreOffice.
- Botones ventana: izquierda.
- Fuentes: Inter + JetBrains Mono.
- Fallback seguro: Adwaita por defecto; WhiteSur sólo opcional.

## Drivers/Firmware

- Wi-Fi Broadcom 2011-2012: `broadcom-sta-dkms`, `firmware-brcm80211`, `linux-headers-amd64`.
- Asistente de firmware faltante: app `Drivers and Firmware` (`macde-drivers` + `isenkram-autoinstall-firmware`).
- Ajustes Mac: `hid_apple fnmode=2`, touchpad libinput, `tlp` y `mbpfan`.

## Limpieza

```bash
./installer/clean-build.sh
./installer/clean-build.sh --all
```

## Nota

Los scripts de netinstall siguen disponibles (`installer/build-netinstall.sh` y `installer/profiles/*`), pero la ruta principal es la ISO live GNOME.
