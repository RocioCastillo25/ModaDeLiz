#!/bin/sh
# Arranque del contenedor de respaldos: programa el respaldo diario con cron.
set -eu

mkdir -p /backups

# cron lanza los trabajos con el entorno vacio: se guardan las variables para que backup.sh las cargue
for v in PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE RETENCION_DIAS BACKUP_DIR; do
  eval "valor=\${$v:-}"
  [ -n "$valor" ] && printf "export %s='%s'\n" "$v" "$valor"
done > /tmp/backup.env
chmod 600 /tmp/backup.env

# Por defecto 04:00 UTC = 22:00 hora de Puebla (UTC-6, sin horario de verano). El horario de cron va en UTC.
HORARIO="${BACKUP_CRON:-0 4 * * *}"
mkdir -p /etc/crontabs
echo "$HORARIO /bin/sh /scripts/backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root

# Primer arranque: se hace un respaldo de inmediato para comprobar que todo funciona
if ! ls /backups/checklizz-*.sql.gz >/dev/null 2>&1; then
  sh /scripts/backup.sh || echo "El primer respaldo fallo; se reintentara en el horario programado."
fi

echo "Respaldo diario programado ($HORARIO, hora UTC). Los archivos quedan en ./backups"
exec crond -f -l 8 -c /etc/crontabs
