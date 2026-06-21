#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> Aplicando migrações do metastore Superset"
superset db upgrade

echo "==> Verificando usuário administrador"
if superset fab list-users 2>/dev/null | grep -Fq "${SUPERSET_ADMIN_USERNAME}"; then
  echo "Usuário ${SUPERSET_ADMIN_USERNAME} já existe."
else
  superset fab create-admin \
    --username "${SUPERSET_ADMIN_USERNAME}" \
    --firstname "${SUPERSET_ADMIN_FIRSTNAME}" \
    --lastname "${SUPERSET_ADMIN_LASTNAME}" \
    --email "${SUPERSET_ADMIN_EMAIL}" \
    --password "${SUPERSET_ADMIN_PASSWORD}"
fi

echo "==> Sincronizando roles e permissões"
superset init

echo "==> Inicialização do Superset concluída"
