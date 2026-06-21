# Atualização da stack

## Arquivos

Copie os arquivos para o projeto respeitando os caminhos:

- `compose.yaml`
- `.env.example`
- `docker/superset/Dockerfile`
- `docker/superset/superset_config.py`
- `docker/superset/init.sh`
- `docker/duckdb/ui_init.sql`
- `scripts/publish_warehouse.py`

## Inicialização

```powershell
Copy-Item .env.example .env
# Edite as senhas e a SUPERSET_SECRET_KEY.

docker compose config
docker compose build

docker compose run --rm pipeline
docker compose up -d superset-db superset-redis superset-web superset-worker
```

Acesse: <http://localhost:8088>

## Conexão DuckDB no Superset

URI:

```text
duckdb:////app/warehouse/football_serving.duckdb
```

Em **Advanced > Engine Parameters**:

```json
{
  "connect_args": {
    "read_only": true
  }
}
```

## Serviços opcionais

```powershell
# Scheduler Celery, quando ativarmos alertas e relatórios
docker compose --profile superset-scheduler up -d superset-beat

# DuckDB UI
docker compose --profile duckdb-ui up -d duckdb-ui

# CLI read-only
docker compose run --rm duckdb-cli
```
