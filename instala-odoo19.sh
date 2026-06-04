#!/bin/bash

# =============================================================================
# instala-odoo19.sh – Orquestador de instalación de Odoo 19 con Docker
# =============================================================================
# Orden de ejecución:
# 1. prepareserver.sh       → swap, mc, docker, docker-compose, portainer, webmin
# 2. PAUSA MANUAL           → el usuario fija la contraseña de Portainer en :9000
# 3. deploy-odoo19-portainer.sh → instalación base de Odoo
# 4. prepare_modules_config.sh  → fichero de config + módulos OCA
# 5. execute_modules_install.sh → clona repositorios OCA
# 6. execute_requirements.sh   → instala librerías Python en el contenedor
# 7. deploy-npm-portainer.sh   → instala Nginx Proxy Manager
# =============================================================================

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/instala-odoo19_$(date +%Y%m%d_%H%M%S).log"
PORTAINER_URL="http://$(hostname -I | awk '{print $1}'):9000"
PORTAINER_PASSWORD_REQUERIDA="000000000000"  # doce ceros

# Lista ordenada de scripts (excepto la pausa manual que se gestiona aparte)
SCRIPTS=(
  "prepareserver.sh"
  "deploy-odoo19-portainer.sh"
  "prepare_modules_config.sh"
  "execute_modules_install.sh"
  "execute_requirements.sh"
  "deploy-npm-portainer.sh"
)

# ─── Funciones de utilidad ───────────────────────────────────────────────────
log()   { echo -e "$*" | tee -a "${LOG_FILE}"; }
info()  { log "${CYAN}[INFO]${RESET} $*"; }
ok()    { log "${GREEN}[OK]${RESET} $*"; }
warn()  { log "${YELLOW}[WARN]${RESET} $*"; }
error() { log "${RED}[ERROR]${RESET} $*"; }

step() {
  log "\n${BOLD}${CYAN}══════════════════════════════════════════════${RESET}"
  log "${BOLD}${CYAN} $*${RESET}"
  log "${BOLD}${CYAN}══════════════════════════════════════════════${RESET}"
}

banner() {
  log ""
  log "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  log "${BOLD}${CYAN}║   Instalación Odoo 19 – Docker + Portainer   ║${RESET}"
  log "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  log ""
}

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

# Comprueba que un script existe y tiene permisos de ejecución
check_script() {
  local script="$1"
  local path="${SCRIPT_DIR}/${script}"
  if [[ ! -f "${path}" ]]; then
    error "No se encuentra el script: ${path}"
    return 1
  fi
  if [[ ! -x "${path}" ]]; then
    warn "El script ${script} no es ejecutable. Añadiendo permisos..."
    chmod +x "${path}"
  fi
}

# Ejecuta un script y registra su salida en el log
run_script() {
  local script="$1"
  local path="${SCRIPT_DIR}/${script}"

  info "[$(timestamp)] Iniciando: ${script}"

  if bash "${path}" 2>&1 | tee -a "${LOG_FILE}"; then
    ok "[$(timestamp)] Completado con éxito: ${script}"
  else
    local exit_code="${PIPESTATUS[0]}"
    error "[$(timestamp)] FALLO en ${script} (código de salida: ${exit_code})"
    error "Revisa el log completo en: ${LOG_FILE}"
    exit "${exit_code}"
  fi
}

# Pausa interactiva para que el usuario configure Portainer
wait_for_portainer() {
  step "PASO 2 de 7 – Configuración manual de Portainer"
  log ""
  log "${YELLOW}┌─────────────────────────────────────────────────────────────┐${RESET}"
  log "${YELLOW}│   ACCIÓN REQUERIDA – Configura la contraseña de Portainer   │${RESET}"
  log "${YELLOW}├─────────────────────────────────────────────────────────────┤${RESET}"
  log "${YELLOW}│                                                             │${RESET}"
  log "${YELLOW}│  1. Abre en tu navegador: ${PORTAINER_URL}                  ${YELLOW}│${RESET}"
  log "${YELLOW}│  2. Introduce la contraseña provisional:                    │${RESET}"
  log "${YELLOW}│     ${BOLD}${PORTAINER_PASSWORD_REQUERIDA}${RESET}${YELLOW} (doce ceros)                       │${RESET}"
  log "${YELLOW}│  3. Completa el asistente de primer inicio de Portainer.    │${RESET}"
  log "${YELLOW}│                                                             │${RESET}"
  log "${YELLOW}│  IMPORTANTE: La instalación de Odoo depende de esta        │${RESET}"
  log "${YELLOW}│  contraseña exacta para conectarse a Portainer vía API.    │${RESET}"
  log "${YELLOW}│                                                             │${RESET}"
  log "${YELLOW}└─────────────────────────────────────────────────────────────┘${RESET}"
  log ""

  while true; do
    read -rp "$(echo -e "${BOLD}¿Has configurado la contraseña de Portainer? [s/N]: ${RESET}")" respuesta
    case "${respuesta,,}" in
      s|si|sí|yes|y)
        ok "Continuando con la instalación..."
        break
        ;;
      n|no|"")
        warn "Esperando... Configura Portainer antes de continuar."
        ;;
      *)
        warn "Respuesta no reconocida. Escribe 's' para continuar o 'n' para esperar."
        ;;
    esac
  done
}

# Comprueba que el script se ejecuta como root
check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    error "Este script debe ejecutarse como root (usa: sudo $0)"
    exit 1
  fi
}

# Resumen final
show_summary() {
  local end_time
  end_time=$(timestamp)
  log ""
  log "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
  log "${BOLD}${GREEN}║          ✔  Instalación completada           ║${RESET}"
  log "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
  log ""
  log "  Odoo 19 está instalado y configurado con:"
  log "   • Docker + Docker Compose"
  log "   • Portainer (gestión de contenedores)"
  log "   • Webmin (administración del servidor)"
  log "   • Módulos OCA + librerías Python"
  log "   • Nginx Proxy Manager (proxy inverso)"
  log ""
  log "  Portainer:    ${PORTAINER_URL}"
  log "  Log completo: ${LOG_FILE}"
  log ""
  log "  Finalizado: ${end_time}"
  log ""
}

# ─── Flujo principal ──────────────────────────────────────────────────────────
main() {
  mkdir -p "${LOG_DIR}"

  banner
  check_root

  info "Directorio de trabajo: ${SCRIPT_DIR}"
  info "Log: ${LOG_FILE}"

  # ── Verificación previa de todos los scripts ─────────────────────────────
  step "Verificando scripts necesarios..."
  for script in "${SCRIPTS[@]}"; do
    check_script "${script}"
    ok " ✔ ${script}"
  done

  # ── PASO 1: Preparar el servidor ─────────────────────────────────────────
  step "PASO 1 de 7 – Preparar servidor (swap, docker, portainer, webmin)"
  run_script "prepareserver.sh"

  # ── PASO 2: Pausa manual – contraseña de Portainer ───────────────────────
  wait_for_portainer

  # ── PASO 3: Desplegar Odoo 19 vía Portainer ──────────────────────────────
  step "PASO 3 de 7 – Desplegar Odoo 19 en Portainer"
  run_script "deploy-odoo19-portainer.sh"

  # ── PASO 4: Configuración y módulos OCA ──────────────────────────────────
  step "PASO 4 de 7 – Añadir fichero de configuración y módulos OCA"
  run_script "prepare_modules_config.sh"

  # ── PASO 5: Clonar repositorios OCA ──────────────────────────────────────
  step "PASO 5 de 7 – Descargar repositorios OCA"
  run_script "execute_modules_install.sh"

  # ── PASO 6: Instalar librerías Python en el contenedor ───────────────────
  step "PASO 6 de 7 – Cargar librerías Python en el contenedor de Odoo"
  run_script "execute_requirements.sh"

  # ── PASO 7: Instalar Nginx Proxy Manager ─────────────────────────────────
  step "PASO 7 de 7 – Instalar Nginx Proxy Manager"
  run_script "deploy-npm-portainer.sh"

  # ── Resumen ───────────────────────────────────────────────────────────────
  show_summary
}

main "$@"
