# MacDE Live ISO (GNOME)

ISO live `amd64` basada en Debian 12 (Bookworm) para MacBook Intel 2011-2012, con GNOME, Calamares y build reproducible.

## Estado actual

- Escritorio: GNOME (`gdm3`, `gnome-shell`, `gnome-control-center`, `task-gnome-desktop`).
- Sesión gráfica por defecto: Xorg (`WaylandEnable=false` en GDM para estabilidad en hardware/vm antiguos).
- Look base: Adwaita + dock inferior (`dash-to-dock`) + DING + wallpaper Mountain.
- WhiteSur: opcional (no forzado en build).
- Apps incluidas: Firefox, GNOME Notes (`bijiben`), VLC, LibreOffice, Synaptic.
- Instalador: Calamares con branding MacDE GNOME, links de soporte al repo y acceso directo en escritorio live (trusted).

## Política Wi-Fi Broadcom

- Driver objetivo: `broadcom-sta-common` + `broadcom-sta-dkms` (`wl`).
- Se purga `b43` userland: `firmware-b43-installer`, `firmware-b43legacy-installer`, `b43-fwcutter`, `b43-openfwwf`.
- Se elimina `/lib/firmware/b43` del live/target.
- Se aplica blacklist en `/etc/modprobe.d/macde-broadcom-wl.conf`:
  - `b43`, `b43legacy`, `ssb`, `bcma`, `brcmsmac`, `brcmfmac`.

## Limpieza KDE en ISO GNOME

- Se purgan `systemsettings` y `kactivitymanagerd`.
- Se ocultan launchers KDE residuales en GNOME:
  - `org.kde*.desktop`
  - `gnome-system-monitor-kde.desktop`
  - iconos `systemsettings_*` del catálogo.

## Estructura relevante

```text
installer/
  build-live.sh
  build-live-in-docker.sh
  build-live-builder-image.sh
  docker/live-builder.Dockerfile
  clean-build.sh
  profiles/macde.postinst
live/config/
  package-lists/macde.list.chroot
  hooks/live/010-install-whitesur.hook.chroot
  hooks/live/020-prune-kde-and-b43.hook.chroot
  hooks/live/999-restore-py3compile.hook.chroot
  includes.chroot/etc/calamares/branding/macde/*
  includes.chroot/etc/modprobe.d/macde-broadcom-wl.conf
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

El contenedor `linux/amd64` es persistente por defecto (`macde-live-builder-amd64`) y reutiliza cachés en `build/docker-cache/`.

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
- Dock: abajo, autohide/intellihide, iconos pequeños DING y favoritos:
  - Firefox
  - Notes
  - Files
  - Terminal
  - Settings
  - VLC
  - LibreOffice Writer
- Botones ventana: izquierda.
- Fuentes: Inter + JetBrains Mono.

## Limpieza

```bash
./installer/clean-build.sh
./installer/clean-build.sh --all
```

## Nota

Los scripts de netinstall siguen disponibles (`installer/build-netinstall.sh` y `installer/profiles/*`), pero la ruta principal es la ISO live GNOME.
