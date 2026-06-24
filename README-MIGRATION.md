# Migração DuckDB → PostgreSQL

## Arquivos incluídos

- `compose.yaml`
- `.env.example`
- `requirements.txt`
- `Dockerfile`
- `.dockerignore`
- `docker/postgres/init/01-create-schemas.sql`
- `docker/superset/Dockerfile`

Os arquivos `docker/superset/init.sh` e
`docker/superset/superset_config.py` existentes podem ser mantidos.

## Mudanças principais

- PostgreSQL 18.4 passa a ser o warehouse (`football-db`);
- PostgreSQL 16.14 permanece como metastore do Superset;
- removidos DuckDB CLI, DuckDB UI, locks e publicação de snapshot;
- removido o volume `warehouse`;
- `pipeline`, `load-raw`, dbt e Jupyter conectam por TCP ao warehouse;
- adicionado `football-psql` para acesso interativo;
- dbt passa de `dbt-duckdb` para `dbt-postgres`;
- o loader Python passa a usar Psycopg 3.

## Antes de executar

1. Substitua os arquivos na raiz do projeto.
2. Crie `docker/postgres/init/` e copie o SQL fornecido.
3. Atualize `.env` usando `.env.example`.
4. Troque todas as credenciais que já tenham sido exibidas em logs.
5. O `scripts/load_raw.py` atual ainda é DuckDB e deverá ser substituído
   antes de executar `load-raw` ou `pipeline`.
6. O projeto dbt deverá receber um `profiles.yml` do tipo `postgres`.

## Primeira validação

```powershell
docker compose config --quiet
docker compose build pipeline superset-web
docker compose up -d football-db
docker compose ps
docker compose run --rm football-psql
```

No `psql`:

```sql
select version();
\dn
```

Resultado esperado: schemas `metadata`, `raw`, `staging`, `core` e `marts`.
