#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Instala Docker, Docker Compose plugin y Portainer CE en Ubuntu 24.04
# - Publica Portainer en 8000 (edge) y 9000 (UI) tal como usas tú
# - Crea la red my-main-net si no existe
################################################################################

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Este script debe ejecutarse como root: sudo $0" >&2
  exit 1
fi

echo "== Actualizando sistema =="
apt update
apt upgrade -y

echo "== Instalando dependencias =="
apt install -y ca-certificates curl gnupg lsb-release

echo "== Añadiendo clave GPG oficial de Docker =="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "== Añadiendo repositorio de Docker =="
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"   > /etc/apt/sources.list.d/docker.list

echo "== Instalando Docker y Docker Compose plugin =="
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "== Habilitando y arrancando Docker =="
systemctl enable docker
systemctl start docker

echo "== Creando red por defecto si no existe =="
docker network create my-main-net >/dev/null 2>&1 || true

echo "== Preparando datos de Portainer =="
PORTAINER_DATA="${HOME:-/root}/portainer_data"
mkdir -p "$PORTAINER_DATA"

if docker ps -a --format '{{.Names}}' | grep -qx 'portainer'; then
  echo "Portainer ya existe (contenedor 'portainer'). No se reinstala."
else
  echo "== Instalando Portainer CE (puertos 8000/9000) =="
  docker run -d     -p 8000:8000     -p 9000:9000     --name portainer     --restart=always     -v /var/run/docker.sock:/var/run/docker.sock     -v "$PORTAINER_DATA":/data     --network=my-main-net     portainer/portainer-ce:latest
fi

echo "=================================================================="
echo "✅ Docker + Portainer listos"
echo "Accede a Portainer en: http://TU_IP:9000"
echo "=================================================================="


# Crear carpeta para datos de Portainer
mkdir -p $HOME/portainer_data

# Instalar Portainer CE con puerto 9000
sudo docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/portainer_data:/data \
  --network=my-main-net \
  portainer/portainer-ce:latest

echo "=================================================================="
echo "✅ Instalación completada"
echo "Accede a Portainer en: http://TU_IP:9000"
echo "=================================================================="
