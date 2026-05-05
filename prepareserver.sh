#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# VPS ORQUESTADOR (ODOO READY)
# Ubuntu 24.04 / Debian-like
#
# Instala:
# - Swap (crítico para Odoo)
# - Base system
# - Docker + Compose plugin
# - Portainer CE (latest)
# - Webmin
# - mc
###############################################################################

#######################################
# CONFIG
#######################################
SWAPFILE="/swapfile"
SWAPSIZE="3G"

PORTAINER_NAME="portainer"
PORTAINER_IMAGE="portainer/portainer-ce:latest"
PORTAINER_DATA="/opt/portainer"
PORTAINER_UI_PORT=9000
PORTAINER_EDGE_PORT=8000

WEBMIN_URL="https://www.webmin.com/download/deb/webmin-current.deb"
WEBMIN_DEB="/tmp/webmin.deb"

#######################################
# ROOT CHECK
#######################################
if [[ "$(id -u)" -ne 0 ]]; then
  echo "❌ Ejecuta como root: sudo $0"
  exit 1
fi

#######################################
# 1. SWAP (CRÍTICO PARA ODOO)
#######################################
echo "== Swap =="

if swapon --show | awk '{print $1}' | grep -qx "$SWAPFILE"; then
  echo "✔ Swap ya activo"
else
  if [[ ! -f "$SWAPFILE" ]]; then
    echo "Creando swap $SWAPSIZE"

    if ! fallocate -l "$SWAPSIZE" "$SWAPFILE"; then
      echo "fallocate falló, usando dd..."
      dd if=/dev/zero of="$SWAPFILE" bs=1M count=3072 status=none
    fi

    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null
  fi

  swapon "$SWAPFILE"

  grep -q "$SWAPFILE" /etc/fstab || \
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab

  echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
  sysctl vm.swappiness=10 >/dev/null
fi

#######################################
# 2. BASE SYSTEM
#######################################
echo "== Base system =="

apt update -y
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  unzip \
  mc

#######################################
# 3. DOCKER
#######################################
echo "== Docker =="

if ! command -v docker >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

  apt update -y

  apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  systemctl enable docker
  systemctl start docker
else
  echo "✔ Docker ya instalado"
fi

#######################################
# 4. PORTAINER
#######################################
echo "== Portainer =="

mkdir -p "$PORTAINER_DATA"

if docker ps -a --format '{{.Names}}' | grep -qx "$PORTAINER_NAME"; then
  echo "✔ Portainer existe, asegurando que esté activo"
  docker start "$PORTAINER_NAME" >/dev/null 2>&1 || true
else
  echo "== Instalando Portainer (latest) =="

  docker run -d \
    --name "$PORTAINER_NAME" \
    --restart=always \
    -p $PORTAINER_UI_PORT:9000 \
    -p $PORTAINER_EDGE_PORT:8000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PORTAINER_DATA":/data \
    portainer/portainer-ce:latest
fi

#######################################
# 5. WEBMIN
#######################################
echo "== Webmin =="

if command -v webmin >/dev/null 2>&1; then
  echo "✔ Webmin ya instalado"
else
  apt install -y \
    perl \
    libnet-ssleay-perl \
    libauthen-pam-perl \
    libio-pty-perl

  wget -q -O "$WEBMIN_DEB" "$WEBMIN_URL"

  dpkg -i "$WEBMIN_DEB" || apt -f install -y

  systemctl enable webmin
  systemctl restart webmin
fi

#######################################
# FINAL
#######################################
echo ""
echo "=================================================="
echo "✅ VPS LISTO"
echo "Docker: OK"
echo "Portainer: http://TU_IP:$PORTAINER_UI_PORT"
echo "Webmin: https://TU_IP:10000"
echo "Swap: $SWAPSIZE"
echo "=================================================="
