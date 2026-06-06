#!/bin/bash

# =============================================================================
# setup_plantilla.sh – Crea la BD plantilla e instala los módulos
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     Setup base de datos plantilla Odoo 19    ║"
echo "╚══════════════════════════════════════════════╝"

echo ""
echo "── PASO 1: Crear base de datos ──────────────────"
bash "${SCRIPT_DIR}/crea_base_datos.sh" || { echo "❌ Falló la creación de la BD"; exit 1; }

echo ""
echo "── PASO 2: Instalar módulos ─────────────────────"
bash "${SCRIPT_DIR}/instala_modulos_plantilla.sh" || { echo "❌ Falló la instalación de módulos"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║          ✔  Plantilla lista                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
