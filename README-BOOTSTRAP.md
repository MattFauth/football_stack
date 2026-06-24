# Bootstrap PostgreSQL + dbt

## Arquivos

- `scripts/load_raw.py`
- `dbt/profiles.yml`
- `dbt/dbt_project.yml`
- `dbt/models/staging/_sources.yml`

## Princípio da camada raw

As colunas são carregadas como `text` para preservar a representação dos
arquivos e desacoplar ingestão de interpretação. Conversões explícitas serão
feitas nos modelos `stg_*`.

Cada tabela é carregada em uma tabela temporária dentro do schema `raw` e
substituída somente após o `COPY` terminar com sucesso.

## Execução

```powershell
docker compose build pipeline
docker compose up -d football-db
docker compose run --rm load-raw
docker compose run --rm shell dbt debug --project-dir /app/dbt --profiles-dir /app/dbt
```

## Validação SQL

```powershell
docker compose run --rm football-psql
```

```sql
\dt raw.*
\dt metadata.*

select
    file_name,
    row_count,
    column_count,
    round(elapsed_seconds::numeric, 2) as seconds
from metadata.ingestion_files
order by loaded_at_utc desc, file_name;
```
