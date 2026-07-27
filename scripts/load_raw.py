from __future__ import annotations

import csv
import hashlib
import json
import os
import re
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import psycopg
from psycopg import sql


EXPECTED_FILES = (
    "appearances.csv",
    "club_games.csv",
    "clubs.csv",
    "competitions.csv",
    "countries.csv",
    "game_events.csv",
    "game_lineups.csv",
    "games.csv",
    "national_teams.csv",
    "player_valuations.csv",
    "players.csv",
    "transfers.csv",
)

ADVISORY_LOCK_KEY = 742_110_983


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as file:
        while chunk := file.read(1024 * 1024):
            digest.update(chunk)

    return digest.hexdigest()


def load_manifest(raw_dir: Path) -> dict[str, Any]:
    path = raw_dir / "manifest.json"

    if not path.exists():
        return {}

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Manifesto inválido em {path}: {exc}") from exc


def manifest_files_by_name(
    manifest: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}

    for item in manifest.get("files", []):
        if isinstance(item, dict) and isinstance(item.get("name"), str):
            result[item["name"]] = item

    return result


def validate_files(raw_dir: Path) -> list[Path]:
    missing = [
        name for name in EXPECTED_FILES
        if not (raw_dir / name).is_file()
    ]

    if missing:
        raise FileNotFoundError(
            "Arquivos ausentes em data/raw: "
            + ", ".join(sorted(missing))
        )

    empty = [
        name for name in EXPECTED_FILES
        if (raw_dir / name).stat().st_size == 0
    ]

    if empty:
        raise RuntimeError(
            "Arquivos vazios: " + ", ".join(sorted(empty))
        )

    return [raw_dir / name for name in EXPECTED_FILES]


def normalize_identifier(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9_]+", "_", value)
    value = re.sub(r"_+", "_", value).strip("_")

    if not value:
        raise ValueError("Identificador vazio encontrado no cabeçalho.")

    if value[0].isdigit():
        value = f"column_{value}"

    return value


def read_header(path: Path) -> list[str]:
    with path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as file:
        reader = csv.reader(file)
        try:
            original = next(reader)
        except StopIteration as exc:
            raise RuntimeError(f"CSV vazio: {path.name}") from exc

    normalized = [normalize_identifier(column) for column in original]

    duplicates = sorted({
        column for column in normalized
        if normalized.count(column) > 1
    })

    if duplicates:
        raise RuntimeError(
            f"Colunas duplicadas em {path.name}: "
            + ", ".join(duplicates)
        )

    return normalized


def connection_string() -> str:
    required = {
        "host": os.getenv("FOOTBALL_DB_HOST", "football-db"),
        "port": os.getenv("FOOTBALL_DB_PORT", "5432"),
        "dbname": os.getenv("FOOTBALL_DB_NAME", "football"),
        "user": os.getenv("FOOTBALL_DB_USER", "football"),
        "password": os.getenv("FOOTBALL_DB_PASSWORD"),
        "sslmode": os.getenv("FOOTBALL_DB_SSLMODE", "disable"),
    }

    if not required["password"]:
        raise RuntimeError("FOOTBALL_DB_PASSWORD não foi definida.")

    return " ".join(
        f"{key}={value}" for key, value in required.items()
    )


def ensure_metadata(connection: psycopg.Connection[Any]) -> None:
    with connection.cursor() as cursor:
        cursor.execute("CREATE SCHEMA IF NOT EXISTS metadata")
        cursor.execute("CREATE SCHEMA IF NOT EXISTS raw")

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS metadata.ingestion_runs (
                run_id uuid PRIMARY KEY,
                dataset_handle text NOT NULL,
                source_version text,
                started_at_utc timestamptz NOT NULL,
                finished_at_utc timestamptz,
                status text NOT NULL
                    CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),
                raw_directory text NOT NULL,
                file_count integer NOT NULL,
                total_rows bigint,
                error_message text
            )
            """
        )

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS metadata.ingestion_files (
                run_id uuid NOT NULL
                    REFERENCES metadata.ingestion_runs(run_id),
                file_name text NOT NULL,
                table_schema text NOT NULL,
                table_name text NOT NULL,
                file_size_bytes bigint NOT NULL,
                file_sha256 text NOT NULL,
                row_count bigint NOT NULL,
                column_count integer NOT NULL,
                loaded_at_utc timestamptz NOT NULL,
                elapsed_seconds double precision NOT NULL,
                PRIMARY KEY (run_id, file_name)
            )
            """
        )


def count_csv_rows(path: Path) -> int:
    # Conta quebras de registro respeitando aspas e campos multilinha.
    with path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as file:
        reader = csv.reader(file)
        next(reader)
        return sum(1 for _ in reader)


def load_table(
    connection: psycopg.Connection[Any],
    path: Path,
    run_suffix: str,
) -> tuple[str, int, int, float]:
    table_name = normalize_identifier(path.stem)
    staging_name = f"__load_{table_name}_{run_suffix}"
    columns = read_header(path)

    started = time.perf_counter()

    create_columns = sql.SQL(", ").join(
        sql.SQL("{} text").format(sql.Identifier(column))
        for column in columns
    )

    with connection.transaction():
        with connection.cursor() as cursor:
            cursor.execute(
                sql.SQL("DROP TABLE IF EXISTS raw.{}").format(
                    sql.Identifier(staging_name)
                )
            )

            cursor.execute(
                sql.SQL("CREATE TABLE raw.{} ({})").format(
                    sql.Identifier(staging_name),
                    create_columns,
                )
            )

            copy_statement = sql.SQL(
                """
                COPY raw.{} ({})
                FROM STDIN
                WITH (
                    FORMAT CSV,
                    HEADER true,
                    ENCODING 'UTF8',
                    DELIMITER ',',
                    QUOTE '"',
                    ESCAPE '"'
                )
                """
            ).format(
                sql.Identifier(staging_name),
                sql.SQL(", ").join(
                    sql.Identifier(column) for column in columns
                ),
            )

            with path.open("rb") as source:
                with cursor.copy(copy_statement) as copy:
                    while chunk := source.read(1024 * 1024):
                        copy.write(chunk)

            cursor.execute(
                sql.SQL("SELECT count(*) FROM raw.{}").format(
                    sql.Identifier(staging_name)
                )
            )
            row_count = int(cursor.fetchone()[0])

            cursor.execute(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'raw'
                  AND table_name = %s
                ORDER BY ordinal_position
                """,
                (table_name,),
            )
            existing_columns = [row[0] for row in cursor.fetchall()]

            if existing_columns:
                if existing_columns != columns:
                    raise RuntimeError(
                        f"Schema de raw.{table_name} mudou. "
                        f"Atual: {existing_columns}; novo: {columns}. "
                        "Ajuste os modelos dependentes antes de recarregar."
                    )

                # Preserva o OID da tabela original para não invalidar as
                # views do dbt que dependem diretamente da camada raw.
                cursor.execute(
                    sql.SQL("TRUNCATE TABLE raw.{}").format(
                        sql.Identifier(table_name)
                    )
                )
                cursor.execute(
                    sql.SQL(
                        "INSERT INTO raw.{} ({}) SELECT {} FROM raw.{}"
                    ).format(
                        sql.Identifier(table_name),
                        sql.SQL(", ").join(
                            sql.Identifier(column) for column in columns
                        ),
                        sql.SQL(", ").join(
                            sql.Identifier(column) for column in columns
                        ),
                        sql.Identifier(staging_name),
                    )
                )
                cursor.execute(
                    sql.SQL("DROP TABLE raw.{}").format(
                        sql.Identifier(staging_name)
                    )
                )
            else:
                cursor.execute(
                    sql.SQL("ALTER TABLE raw.{} RENAME TO {}").format(
                        sql.Identifier(staging_name),
                        sql.Identifier(table_name),
                    )
                )

            cursor.execute(
                sql.SQL(
                    "COMMENT ON TABLE raw.{} IS {}"
                ).format(
                    sql.Identifier(table_name),
                    sql.Literal(
                        f"Landing table carregada de {path.name}; "
                        "colunas preservadas como text."
                    )
                )
            )

    elapsed = time.perf_counter() - started
    return table_name, row_count, len(columns), elapsed


def main() -> int:
    raw_dir = Path(
        os.getenv("RAW_DATA_DIR", "/app/data/raw")
    ).resolve()

    dataset_handle = os.getenv(
        "DATASET_HANDLE",
        "davidcariboo/player-scores",
    )

    source_files = validate_files(raw_dir)
    manifest = load_manifest(raw_dir)
    manifest_file_map = manifest_files_by_name(manifest)

    source_version = (
        manifest.get("version")
        or manifest.get("dataset_version")
        or manifest.get("kaggle_version")
    )

    run_id = uuid.uuid4()
    run_suffix = run_id.hex[:12]
    started_at = utc_now()

    print(f"Run ID: {run_id}")
    print(f"Dataset: {dataset_handle}")
    print(f"Versão: {source_version or 'não informada'}")
    print(f"Origem: {raw_dir}")
    print()

    connection: psycopg.Connection[Any] | None = None

    try:
        connection = psycopg.connect(
            connection_string(),
            autocommit=False,
            application_name="football-load-raw",
        )

        ensure_metadata(connection)
        connection.commit()

        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT pg_advisory_lock(%s)",
                (ADVISORY_LOCK_KEY,),
            )

            cursor.execute(
                """
                INSERT INTO metadata.ingestion_runs (
                    run_id,
                    dataset_handle,
                    source_version,
                    started_at_utc,
                    status,
                    raw_directory,
                    file_count
                )
                VALUES (%s, %s, %s, %s, 'RUNNING', %s, %s)
                """,
                (
                    run_id,
                    dataset_handle,
                    str(source_version) if source_version else None,
                    started_at,
                    str(raw_dir),
                    len(source_files),
                ),
            )
        connection.commit()

        total_rows = 0

        for index, path in enumerate(source_files, start=1):
            print(
                f"[{index:02d}/{len(source_files):02d}] "
                f"Carregando {path.name}..."
            )

            table_name, row_count, column_count, elapsed = load_table(
                connection,
                path,
                run_suffix,
            )

            total_rows += row_count
            manifest_item = manifest_file_map.get(path.name, {})
            file_sha256 = manifest_item.get("sha256")

            if not isinstance(file_sha256, str) or not file_sha256:
                file_sha256 = sha256_file(path)

            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO metadata.ingestion_files (
                        run_id,
                        file_name,
                        table_schema,
                        table_name,
                        file_size_bytes,
                        file_sha256,
                        row_count,
                        column_count,
                        loaded_at_utc,
                        elapsed_seconds
                    )
                    VALUES (
                        %s, %s, 'raw', %s, %s, %s,
                        %s, %s, %s, %s
                    )
                    """,
                    (
                        run_id,
                        path.name,
                        table_name,
                        path.stat().st_size,
                        file_sha256,
                        row_count,
                        column_count,
                        utc_now(),
                        elapsed,
                    ),
                )
            connection.commit()

            print(
                f"       raw.{table_name}: "
                f"{row_count:,} linhas, "
                f"{column_count} colunas, "
                f"{elapsed:.2f}s"
            )

        with connection.cursor() as cursor:
            cursor.execute(
                """
                UPDATE metadata.ingestion_runs
                SET
                    finished_at_utc = %s,
                    status = 'SUCCESS',
                    total_rows = %s
                WHERE run_id = %s
                """,
                (utc_now(), total_rows, run_id),
            )
        connection.commit()

        print()
        print("Carga raw concluída com sucesso.")
        print(f"Tabelas: {len(source_files)}")
        print(f"Linhas: {total_rows:,}")
        return 0

    except Exception as exc:
        if connection is not None:
            try:
                connection.rollback()
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        UPDATE metadata.ingestion_runs
                        SET
                            finished_at_utc = %s,
                            status = 'FAILED',
                            error_message = %s
                        WHERE run_id = %s
                        """,
                        (utc_now(), str(exc)[:8000], run_id),
                    )
                connection.commit()
            except Exception:
                pass

        print(f"Erro na carga raw: {exc}", file=sys.stderr)
        return 1

    finally:
        if connection is not None:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        "SELECT pg_advisory_unlock(%s)",
                        (ADVISORY_LOCK_KEY,),
                    )
                connection.commit()
            except Exception:
                pass
            connection.close()


if __name__ == "__main__":
    raise SystemExit(main())
