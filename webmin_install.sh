#!/usr/bin/env bash
set -euo pipefail

# Webmin en Ubuntu 24.04 instalando desde .deb y resolviendo dependencias.
# Acceso típico: https://TU_IP:10000

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Este script debe ejecutarse como root (sudo)." >&2
  exit 1
fi

if command -v webmin >/dev/null 2>&1; then
  echo "Webmin ya está instalado. No se hace nada."
  exit 0
fi

WORKDIR="/tmp/webmin-install"
DEB_URL="https://www.webmin.com/download/deb/webmin-current.deb"
DEB_FILE="${WORKDIR}/webmin-current.deb"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "== Instalando dependencias =="
apt update
apt install -y wget libnet-ssleay-perl libauthen-pam-perl libio-pty-perl unzip

echo "== Descargando Webmin =="
wget -q -O "$DEB_FILE" "$DEB_URL"

echo "== Instalando Webmin (.deb) =="
dpkg -i "$DEB_FILE" || apt -f install -y

echo "== Habilitando servicio Webmin =="
systemctl enable webmin
systemctl restart webmin

echo "== Estado del servicio =="
systemctl status webmin --no-pager || true

echo "✅ Webmin instalado. Acceso: https://TU_IP:10000"

