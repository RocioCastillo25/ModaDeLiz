#!/bin/sh
# Respaldo de la base de datos con pg_dump (RNF-08), comprimido con gzip.
# Lo ejecuta cron a diario (ver entrypoint.sh) y tambien se puede lanzar a mano:
#   docker compose exec backup sh /scripts/backup.sh
set -eu

# cron no hereda el entorno: entrypoint.sh lo guarda en este archivo
[ -f /tmp/backup.env ] && . /tmp/backup.env

DESTINO="${BACKUP_DIR:-/backups}"
RETENCION="${RETENCION_DIAS:-14}"

# El nombre lleva la hora de Puebla (UTC-6; Mexico ya no usa horario de verano) para reconocerlo facil
AHORA_LOCAL=$(date -u -d "@$(( $(date -u +%s) - 21600 ))" +%Y-%m-%d_%H-%M-%S)
ARCHIVO="$DESTINO/checklizz-$AHORA_LOCAL.sql.gz"
TMP="$DESTINO/.parcial-$$.sql"

mkdir -p "$DESTINO"
# Si algo falla a medias, no se deja un archivo incompleto que parezca un respaldo bueno
trap 'rm -f "$TMP" "$TMP.gz"' EXIT

echo "[$(date -u +%FT%TZ)] Respaldando '$PGDATABASE' desde '$PGHOST'..."
# --clean --if-exists: el .sql borra y recrea las tablas, asi se puede restaurar sobre una base existente
pg_dump --clean --if-exists --no-owner --no-privileges -f "$TMP"
gzip -9 "$TMP"
gzip -t "$TMP.gz"

# Comprobacion minima: un respaldo sin tablas es un respaldo roto
TABLAS=$(gzip -dc "$TMP.gz" | grep -c '^CREATE TABLE' || true)
if [ "$TABLAS" -lt 1 ]; then
  echo "[$(date -u +%FT%TZ)] ERROR: el respaldo no contiene tablas; se descarta." >&2
  exit 1
fi

mv "$TMP.gz" "$ARCHIVO"
echo "[$(date -u +%FT%TZ)] Listo: $ARCHIVO ($(wc -c < "$ARCHIVO") bytes, $TABLAS tablas)"

# Rotacion: se borran los respaldos mas viejos que RETENCION_DIAS
find "$DESTINO" -name 'checklizz-*.sql.gz' -mtime +"$RETENCION" -exec rm -f {} \; -exec echo "Eliminado por antiguo: {}" \;
echo "Respaldos guardados: $(find "$DESTINO" -name 'checklizz-*.sql.gz' | wc -l) (se conservan $RETENCION dias)"
