#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1'. Instálalo y reintenta." >&2; exit 1; }; }
need_cmd python3

read -r -p "Nombre de empresa/proyecto (slug, ej: empresa): " PROJECT
PROJECT="$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')"
if [[ -z "$PROJECT" ]]; then
  echo "Proyecto vacío o inválido. Usa letras/números/guiones." >&2
  exit 1
fi

read -r -p "Versión de Odoo (ej: 18): " ODOO_VERSION
ODOO_VERSION="$(echo "$ODOO_VERSION" | tr -cd '0-9')"
if [[ -z "$ODOO_VERSION" ]]; then
  echo "Versión inválida. Debe ser numérica." >&2
  exit 1
fi

BASE_DOMAIN="aplicacionodoo.com"
INSTANCE_NUM="01"
MACHINE_NAME="${PROJECT}-odoo${ODOO_VERSION}-${INSTANCE_NUM}"
OUTFILE="${MACHINE_NAME}-hoja-claves.txt"

gen_pw() {
python3 - <<'PY'
import secrets, string

LENGTH = 40
SYMBOLS = "!@#$%^&*()-_=+[]{}:,.?/"
UPPER = string.ascii_uppercase
LOWER = string.ascii_lowercase
DIGITS = string.digits

MIDDLE_LEN = LENGTH - 2
ALPHABET = UPPER + LOWER + DIGITS + SYMBOLS

def valid(p: str) -> bool:
    middle = p[1:-1]
    return (
        len(p) == LENGTH and
        p[0] in UPPER and
        p[-1] in UPPER and
        any(c in LOWER for c in middle) and
        any(c in DIGITS for c in middle) and
        any(c in SYMBOLS for c in middle)
    )

while True:
    pw = (
        secrets.choice(UPPER) +
        ''.join(secrets.choice(ALPHABET) for _ in range(MIDDLE_LEN)) +
        secrets.choice(UPPER)
    )
    if valid(pw):
        print(pw)
        break
PY
}

ROOT_PASSWORD="$(gen_pw)"
PORTAINER_PASSWORD="$(gen_pw)"
NGINX_PASSWORD="$(gen_pw)"
ODOO_SUPERADMIN_PASSWORD="$(gen_pw)"
ODOO_ADMIN_PASSWORD="$(gen_pw)"

umask 077
cat > "$OUTFILE" <<EOF
PROYECTO: ${PROJECT}
ODOO_VERSION: ${ODOO_VERSION}
INSTANCIA: ${INSTANCE_NUM}
BASE_DOMAIN: ${BASE_DOMAIN}

NOMBRE_MAQUINA: ${MACHINE_NAME}

DOMINIOS:
- ODOO: ${PROJECT}.${BASE_DOMAIN}
- PORTAINER: portainer.${PROJECT}.${BASE_DOMAIN}
- NGINX: nginx.${PROJECT}.${BASE_DOMAIN}
- WEBMIN: webmin.${PROJECT}.${BASE_DOMAIN}

CREDENCIALES (40 chars; 1º y último MAYÚSCULA):

1) ROOT
   Usuario: root
   Gestor: root ${MACHINE_NAME}
   Password: ${ROOT_PASSWORD}

2) PORTAINER
   Usuario: admin
   Gestor: portainer ${MACHINE_NAME}
   Password: ${PORTAINER_PASSWORD}

3) NGINX
   Usuario: fgarcia@humanoide.es
   Gestor: nginx ${MACHINE_NAME}
   Password: ${NGINX_PASSWORD}

4) ODOO SUPERADMIN (admin_passwd)
   Usuario: (no aplica)
   Gestor: superadminpassword ${MACHINE_NAME}
   Password: ${ODOO_SUPERADMIN_PASSWORD}

5) ODOO ADMIN
   Usuario: admin
   Gestor: admin ${MACHINE_NAME}
   Password: ${ODOO_ADMIN_PASSWORD}
EOF

chmod 600 "$OUTFILE"
echo "OK: generado '$OUTFILE' (permisos 600)"
