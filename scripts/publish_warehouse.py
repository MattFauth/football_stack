from __future__ import annotations

import hashlib
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

import duckdb


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def env_path(name: str, default: str) -> Path:
    return Path(os.getenv(name, default)).resolve()


def validate_snapshot(path: Path) -> dict[str, int]:
    connection = duckdb.connect(str(path), read_only=True)
    try:
        schema_count = connection.execute(
            """
            select count(*)
            from information_schema.schemata
            where schema_name not in ('information_schema', 'pg_catalog')
            """
        ).fetchone()[0]
        table_count = connection.execute(
            """
            select count(*)
            from information_schema.tables
            where table_schema not in ('information_schema', 'pg_catalog')
            """
        ).fetchone()[0]
    finally:
        connection.close()

    if table_count == 0:
        raise RuntimeError("O snapshot não contém tabelas ou views publicáveis.")

    return {
        "schema_count": int(schema_count),
        "table_count": int(table_count),
    }


def publish() -> None:
    build_path = env_path(
        "DUCKDB_BUILD_PATH",
        "/app/warehouse/football_build.duckdb",
    )
    serving_path = env_path(
        "DUCKDB_SERVING_PATH",
        "/app/warehouse/football_serving.duckdb",
    )

    if not build_path.is_file():
        raise FileNotFoundError(f"Banco de build não encontrado: {build_path}")

    serving_path.parent.mkdir(parents=True, exist_ok=True)

    # Consolida eventual WAL antes da cópia.
    connection = duckdb.connect(str(build_path))
    try:
        connection.execute("CHECKPOINT")
    finally:
        connection.close()

    temporary_path = serving_path.with_suffix(serving_path.suffix + ".tmp")
    previous_path = serving_path.with_suffix(serving_path.suffix + ".previous")
    manifest_path = serving_path.with_suffix(serving_path.suffix + ".manifest.json")

    temporary_path.unlink(missing_ok=True)
    shutil.copy2(build_path, temporary_path)

    validation = validate_snapshot(temporary_path)

    if serving_path.exists():
        shutil.copy2(serving_path, previous_path)

    # Substituição dentro do mesmo diretório: leitores existentes continuam
    # no snapshot anterior e novas conexões passam a enxergar o novo arquivo.
    os.replace(temporary_path, serving_path)

    manifest = {
        "published_at_utc": datetime.now(timezone.utc).isoformat(),
        "source": str(build_path),
        "target": str(serving_path),
        "size_bytes": serving_path.stat().st_size,
        "sha256": sha256(serving_path),
        **validation,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    publish()
