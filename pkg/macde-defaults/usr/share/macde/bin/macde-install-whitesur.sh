#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
VENDOR_DIR="/usr/share/macde/vendor"
FAKEBIN_DIR="$WORKDIR/fakebin"
HEADLESS_MODE="${MACDE_HEADLESS:-0}"
trap 'rm -rf "$WORKDIR"' EXIT INT TERM

install_sddm_themes() {
  repo_dir="$1"
  theme_src="$repo_dir/WhiteSur-5.0"
  images_dir="$repo_dir/images"

  install -d /usr/share/sddm/themes

  for variant in light dark; do
    dest="/usr/share/sddm/themes/WhiteSur-$variant"

    rm -rf "$dest"
    cp -r "$theme_src" "$dest"
    cp "$images_dir/background-$variant.jpeg" "$dest/background.jpeg"
    cp "$images_dir/preview-$variant.jpeg" "$dest/preview.jpeg"

    sed -i "/^Name=/s/WhiteSur/WhiteSur-$variant/" "$dest/metadata.desktop"
    sed -i "/^Theme-Id=/s/WhiteSur/WhiteSur-$variant/" "$dest/metadata.desktop"
    sed -i "s/WhiteSur/WhiteSur-$variant/g" "$dest/Main.qml"
  done
}

extract_archive() {
  archive="$1"
  dest="$2"

  mkdir -p "$dest"
  tar -xzf "$archive" -C "$dest"
}

download_and_extract() {
  name="$1"
  url="$2"
  dest="$3"

  archive="$WORKDIR/$name.tar.gz"
  curl -fsSL "$url" -o "$archive"
  extract_archive "$archive" "$dest"
}

extract_or_download() {
  name="$1"
  local_archive="$2"
  url="$3"
  dest="$4"

  if [ -f "$local_archive" ]; then
    extract_archive "$local_archive" "$dest"
  else
    download_and_extract "$name" "$url" "$dest"
  fi
}

ensure_pkg() {
  if ! dpkg -s "$1" >/dev/null 2>&1; then
    MISSING_PKGS="${MISSING_PKGS:-} $1"
  fi
}

for pkg in curl ca-certificates qt5-style-kvantum; do
  ensure_pkg "$pkg"
done

if [ "$HEADLESS_MODE" != "1" ]; then
  for pkg in sassc libglib2.0-dev-bin libxml2-utils; do
    ensure_pkg "$pkg"
  done
fi

if [ -n "${MISSING_PKGS:-}" ]; then
  apt-get update
  apt-get install -y $MISSING_PKGS
fi

extract_or_download \
  "whitesur-kde" \
  "$VENDOR_DIR/whitesur-kde.tar.gz" \
  "https://github.com/vinceliuice/WhiteSur-kde/archive/refs/heads/master.tar.gz" \
  "$WORKDIR"
extract_or_download \
  "whitesur-icons" \
  "$VENDOR_DIR/whitesur-icons.tar.gz" \
  "https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.tar.gz" \
  "$WORKDIR"
extract_or_download \
  "whitesur-cursors" \
  "$VENDOR_DIR/whitesur-cursors.tar.gz" \
  "https://github.com/vinceliuice/WhiteSur-cursors/archive/refs/heads/master.tar.gz" \
  "$WORKDIR"
extract_or_download \
  "whitesur-gtk" \
  "$VENDOR_DIR/whitesur-gtk.tar.gz" \
  "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.tar.gz" \
  "$WORKDIR"

export QT_QPA_PLATFORM=offscreen
export HOME=/root
export USER=root
export LOGNAME=root

install -d "$FAKEBIN_DIR"
cat > "$FAKEBIN_DIR/logname" <<'EOF'
#!/bin/sh
echo "${LOGNAME:-root}"
EOF
chmod +x "$FAKEBIN_DIR/logname"
export PATH="$FAKEBIN_DIR:$PATH"

cd "$WORKDIR/WhiteSur-kde-master"
./install.sh -c light -w default
install_sddm_themes "$WORKDIR/WhiteSur-kde-master/sddm"

if [ "$HEADLESS_MODE" != "1" ]; then
  cd "$WORKDIR/WhiteSur-gtk-theme-master"
  ./install.sh -d /usr/share/themes -c light -o normal
fi

cd "$WORKDIR/WhiteSur-icon-theme-master"
./install.sh -d /usr/share/icons -a

cd "$WORKDIR/WhiteSur-cursors-master"
./install.sh

install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/macde-whitesur.conf <<'EOF'
[Theme]
Current=breeze
EOF

echo
echo "WhiteSur instalado."
echo "En el siguiente inicio de sesion KDE se aplicara el tema global."
