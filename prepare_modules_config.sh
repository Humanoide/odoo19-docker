#!/bin/bash

set -e

echo "🚀 Creando estructura de addons..."

mkdir -p /data/compose/1/addons/otros

echo "📦 Copiando módulos..."
cp -r /root/odoo18-docker/login_user_detail /data/compose/1/addons/otros/ 2>/dev/null || true
cp -r /root/odoo18-docker/supermodulo18 /data/compose/1/addons/otros/ 2>/dev/null || true

echo "📄 Copiando scripts y ficheros de configuración..."
cp /root/odoo18-docker/modules_install_18.txt /data/compose/1/addons/ 2>/dev/null || true
cp /root/odoo18-docker/requirements_oca.sh /data/compose/1/addons/ 2>/dev/null || true
cp /root/odoo18-docker/update_oca.sh /data/compose/1/addons/ 2>/dev/null || true

echo "⚙️ Copiando configuración de Odoo..."
mkdir -p /data/compose/1/config
cp /root/odoo18-docker/odoo.conf /data/compose/1/config/

echo "🔐 Ajustando permisos..."
chmod 644 /data/compose/1/config/odoo.conf

echo "✅ Proceso finalizado correctamente"
