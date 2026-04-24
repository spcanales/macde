# MacDE Live ISO

Starter kit para construir una ISO live `amd64` basada en Debian + KDE Plasma, orientada a un MacBook Pro 15" Mid 2012 (`MacBookPro9,1`), con el escritorio ya ajustado a un look & feel tipo macOS y un instalador gráfico listo dentro del live.

## Objetivo

- Base estable: Debian Bookworm live para `amd64`.
- Escritorio curado: Plasma completo en experiencia, pero sin arrastrar el metapaquete KDE gigante.
- Apariencia tipo Mac lista al arrancar: panel superior, dock, botones a la izquierda, WhiteSur, iconos, cursores y login claro.
- Objetivo de hardware: MacBook Pro 15" Mid 2012 con Intel HD 4000 + NVIDIA GT 650M y Wi-Fi Broadcom.
- Flujo de uso: arrancar en modo live, probar, y si quieres instalar ejecutar Calamares desde el escritorio.

## Qué incluye

- `live/config/package-lists/macde.list.chroot`: selección de paquetes del live.
- `live/config/hooks/live/010-install-whitesur.hook.chroot`: instala WhiteSur durante el build y limpia dependencias temporales.
- `live/config/includes.chroot/etc/calamares`: branding y ajustes del instalador gráfico.
- `pkg/macde-defaults`: paquete `.deb` con defaults de Plasma/SDDM y script de primer arranque.
- `installer/build-live.sh`: build nativo con `live-build`.
- `installer/build-live-builder-image.sh`: crea/actualiza la imagen Docker de build (`linux/amd64`) con dependencias preinstaladas.
- `installer/build-live-in-docker.sh`: build desde macOS usando Docker con contenedor Debian `linux/amd64`.
- `installer/clean-build.sh`: limpia artefactos temporales grandes y conserva la ISO por defecto.

## Cómo funciona

1. En una máquina Debian/Ubuntu de build, ejecutas `installer/build-live.sh`.
2. El script empaqueta `pkg/macde-defaults` como `.deb`.
3. El paquete local y los assets de WhiteSur se inyectan en el arbol de `live-build`.
4. Un hook instala WhiteSur dentro del chroot del live antes de generar la ISO.
5. Al arrancar el live, KDE ya entra con la apariencia MacDE.
6. En el escritorio aparece `Install MacDE`, que lanza Calamares.
7. Al instalar, el sistema conserva el look & feel pero elimina los paquetes live-only del instalador.

## Ajustes para MacBookPro9,1

La selección de paquetes está enfocada en este equipo:

- `broadcom-sta-dkms` + `linux-headers-amd64`: para el Wi-Fi Broadcom de este modelo.
- `intel-microcode`: microcode actualizado para Ivy Bridge.
- `firmware-brcm80211`: firmware Wi-Fi relevante para Broadcom en este modelo.
- `tlp` + `mbpfan`: energía y ventiladores, importantes en un MacBook Pro Intel viejo.
- `appmenu-gtk*`: mejora la integración del menú global en el panel superior.
- `calamares-settings-debian`: base del instalador gráfico, rebrandeada localmente como MacDE.

Nota importante sobre GPU:

- Este equipo tiene doble gráfica. Según la wiki de Debian para `MacBookPro9,1`, la integrada Intel da mejor batería y menos temperatura, mientras que la NVIDIA con `nouveau` es la ruta útil si necesitas monitor externo.

## Requisitos del builder

- Debian o Ubuntu.
- `live-build`
- `debootstrap`
- `dpkg-deb`
- acceso a los mirrors de Debian

Instalación típica en el builder:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap dpkg-dev debhelper xorriso squashfs-tools dosfstools grub-pc-bin grub-efi-amd64-bin mtools curl rsync
```

## Build

Build nativo sobre Linux:

```bash
cd /ruta/a/macde
./installer/build-live.sh
```

Build desde macOS con Docker (primer uso):

```bash
cd /ruta/a/macde
./installer/build-live-builder-image.sh
```

Build incremental desde macOS con Docker:

```bash
cd /ruta/a/macde
./installer/build-live-in-docker.sh
```

Por defecto usa contenedor `linux/amd64` persistente (`macde-live-builder-amd64`) + cachés en `build/docker-cache/`:

- `apt-cache` y `apt-lists` (no reinstala dependencias cada build)
- `live-build-cache` (reutiliza paquetes del rootfs live)
- `theme-cache` (reutiliza tarballs WhiteSur)
- `workdir` (reutiliza el árbol de build dentro del contenedor)

Recrear el contenedor persistente (por ejemplo, si cambiaste Dockerfile/base):

```bash
MACDE_DOCKER_RECREATE=1 ./installer/build-live-in-docker.sh
```

Forzar modo efímero (como antes, `docker run --rm`):

```bash
MACDE_DOCKER_PERSISTENT=0 ./installer/build-live-in-docker.sh
```

Cambiar nombre del contenedor persistente:

```bash
MACDE_LIVE_BUILDER_CONTAINER=macde-builder-dev ./installer/build-live-in-docker.sh
```

Recuperar la ISO manualmente desde el contenedor persistente (si falló el copiado al host):

```bash
docker cp macde-live-builder-amd64:/cache/workdir/macde-build/build/images/live/macde-live-amd64-amd64.hybrid.iso ./build/images/live/
```

En Mac Apple Silicon, la emulación `amd64` sigue siendo más lenta que en host x86_64.

Si cambias dependencias del builder y quieres forzar rebuild de imagen:

```bash
MACDE_DOCKER_REBUILD=1 ./installer/build-live-in-docker.sh
```

Si solo quieres validar la configuración sin construir la ISO completa:

```bash
cd /ruta/a/macde
MACDE_SKIP_LB_BUILD=1 ./installer/build-live-in-docker.sh
```

Salida esperada:

- `build/macde-defaults_all.deb`
- una ISO live dentro de `build/images/live`

Limpieza segura del workspace de build:

```bash
cd /ruta/a/macde
./installer/clean-build.sh
```

Para borrar tambien las ISOs generadas:

```bash
cd /ruta/a/macde
./installer/clean-build.sh --all
```

## Resultado esperado

Al arrancar la ISO:

- entra al escritorio Plasma ya tematizado;
- aparece el acceso directo `Install MacDE` en el escritorio;
- si instalas desde Calamares, el sistema instalado mantiene el tema, iconos, cursores y ajustes base.

## WhiteSur

WhiteSur ya no es una fase manual posterior: el build live lo instala durante la construcción de la imagen. El helper `pkg/macde-defaults/usr/share/macde/bin/macde-install-whitesur.sh` se mantiene por si quieres reinstalar o retocar el tema después.

Componentes incluidos:

- `WhiteSur-kde`
- `WhiteSur-icon-theme`
- `WhiteSur-cursors`
- tema SDDM WhiteSur claro

## Decisiones técnicas

- No se usan temas clonados de Apple ni fuentes propietarias.
- La estética tipo Mac se consigue combinando defaults propios de Plasma con WhiteSur instalado durante el build.
- El instalador visible dentro del live es Calamares, con branding local `MacDE`.
- El build queda fijado a `amd64`, porque el objetivo ya no es Apple Silicon sino un MacBook Intel 2012.

## Límites actuales

- Los assets de WhiteSur y cachés del build Docker quedan en `build/docker-cache/` (no se versionan).
- El layout está diseñado para Plasma 5/Bookworm y puede requerir ajustes menores en Plasma 6.
- El live instala WhiteSur para Plasma, iconos, cursores y SDDM. La capa GTK no queda preinstalada en este build headless para no volver frágil la generación de la ISO.
- No probé todavía la instalación real sobre el MacBookPro9,1 concreto; la parte más sensible seguirá siendo Broadcom + GPU dual.
- Si tu equipo resulta ser la variante Retina de 2012, habrá que ajustar resolución/escala y posiblemente la estrategia gráfica.

## Legacy

Los scripts de netinstall anteriores siguen en `installer/build-netinstall.sh` y `installer/profiles/`, pero la ruta principal ahora es la ISO live.
