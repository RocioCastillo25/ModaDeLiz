# Respaldo de la base de datos (RNF-08)

El servicio `backup` del `docker-compose.yml` hace un **respaldo diario a las 10:00 pm (hora de Puebla)**
con `pg_dump`, lo comprime y lo guarda en la carpeta **`backups/`** del proyecto (no se sube a Git).
Conserva los últimos **14 días** y borra los más viejos.

- Cada archivo se llama `checklizz-AAAA-MM-DD_HH-MM-SS.sql.gz`.
- Al levantar el sistema por primera vez hace un respaldo inmediato para comprobar que funciona.
- Si un respaldo sale vacío o corrupto se descarta y queda el error en los logs.

## Comandos útiles

Respaldo manual (por ejemplo, antes de la demo):

```bash
docker compose exec backup sh /scripts/backup.sh
```

Ver qué respaldos hay y si cron los está haciendo:

```bash
ls -lh backups/
docker compose logs --tail 20 backup
```

## Restaurar

El respaldo incluye `DROP TABLE IF EXISTS` + `CREATE TABLE`, así que se restaura **sobre la base existente**.
**Esto reemplaza los datos actuales**: haz antes un respaldo manual si no estás seguro.

```bash
gunzip -c backups/checklizz-AAAA-MM-DD_HH-MM-SS.sql.gz | docker exec -i checklizz-postgres psql -U checklizz -d checklizz
```

Para probar un respaldo sin tocar la base real, restáuralo en una base temporal:

```bash
docker exec checklizz-postgres createdb -U checklizz prueba_restauracion
gunzip -c backups/ARCHIVO.sql.gz | docker exec -i checklizz-postgres psql -U checklizz -d prueba_restauracion
docker exec checklizz-postgres dropdb -U checklizz prueba_restauracion
```

## Configuración (opcional, en `.env`)

| Variable | Por defecto | Qué hace |
|---|---|---|
| `BACKUP_RETENCION_DIAS` | `14` | Días que se conservan los respaldos |
| `BACKUP_CRON` | `0 4 * * *` | Horario en formato cron y **hora UTC** (04:00 UTC = 22:00 en Puebla) |

> Los respaldos viven en la misma computadora que la base de datos. Para que protejan de verdad
> (disco dañado, robo), copia la carpeta `backups/` de vez en cuando a una USB o a la nube.
