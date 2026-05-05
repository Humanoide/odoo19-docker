#!/usr/bin/env bash
# setup_base_force_swap.sh - Fuerza /swapfile 3G + update + mc + Webmin (sin UFW)
set -euo pipefail

log(){ printf "\n\033[1;32m[+] %s\033[0m\n" "$*"; }
warn(){ printf "\n\033[1;33m[!] %s\033[0m\n" "$*"; }

SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then SUDO="sudo"; fi

### 1) (Re)crear /swapfile de 3G SIEMPRE
force_swap(){
  local SWAPFILE="/swapfile"
  local SWAPSIZE="3G"

  # Si /swapfile está activa, desactívala antes de recrear
  if swapon --show | awk '{print $1}' | grep -qx "$SWAPFILE"; then
    log "Desactivando swap existente en $SWAPFILE..."
    $SUDO swapoff "$SWAPFILE"
  fi

  # Elimina archivo previo si existe y no está en uso
  if [ -f "$SWAPFILE" ]; then
    log "Eliminando $SWAPFILE previo..."
    $SUDO rm -f "$SWAPFILE"
  fi

  log "Creando $SWAPFILE de $SWAPSIZE..."
  if ! $SUDO fallocate -l "$SWAPSIZE" "$SWAPFILE" 2>/dev/null; then
    warn "fallocate no disponible; uso dd..."
    $SUDO dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((3*1024)) status=progress
  fi

  $SUDO chmod 600 "$SWAPFILE"
  $SUDO chown root:root "$SWAPFILE"
  $SUDO mkswap "$SWAPFILE" >/dev/null
  $SUDO swapon "$SWAPFILE"

  # Asegura persistencia en /etc/fstab: reemplaza línea existente o añade
  if grep -qE "^\s*${SWAPFILE}\s+" /etc/fstab; then
    $SUDO sed -i "s#^\s*${SWAPFILE}\s\+.*#${SWAPFILE} none swap sw 0 0#" /etc/fstab
  else
    echo "${SWAPFILE} none swap sw 0 0" | $SUDO tee -a /etc/fstab >/dev/null
  fi

  log "Swap activas ahora:"
  swapon --show
  free -h
}

### 2) Actualizar sistema
system_update(){
  log "Actualizando índices APT..."
  $SUDO apt update -y
  log "Aplicando actualizaciones (full-upgrade)..."
  DEBIAN_FRONTEND=noninteractive $SUDO apt full-upgrade -y
  log "Limpiando paquetes no usados..."
  $SUDO apt autoremove -y
}

### 3) Instalar mc (Midnight Commander)
install_mc(){
  log "Instalando Midnight Commander..."
  $SUDO apt update -y
  $SUDO apt install -y mc
  mc --version || true
}

### 4) Instalar Webmin (repo oficial)
install_webmin(){
  if dpkg -s webmin >/dev/null 2>&1; then
    log "Webmin ya instalado."
    return 0
  fi
  log "Configurando repositorio oficial de Webmin..."
  TMP_SCRIPT="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh -o "$TMP_SCRIPT"
  
  # Responde "yes" automáticamente a cualquier prompt de ese script
  # (solo afecta a ese script)
  yes | $SUDO sh "$TMP_SCRIPT"

  rm -f "$TMP_SCRIPT"

  log "Instalando Webmin..."
  $SUDO apt update -y
  DEBIAN_FRONTEND=noninteractive $SUDO apt install -y webmin

  log "Accede a Webmin: https://<IP-o-dominio>:10000/ (certificado inicial autofirmado)"
}

### Ejecución
force_swap
system_update
install_mc
install_webmin

log "Todo listo. Si el kernel se actualizó, considera reiniciar: sudo reboot"
