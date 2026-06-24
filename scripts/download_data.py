from __future__ import annotations
import argparse
import hashlib
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path
import kagglehub


DATASET_HANDLE = os.getenv("DATASET_HANDLE", "davidcariboo/player-scores")
RAW_DATA_DIR = Path(os.getenv("RAW_DATA_DIR", "/app/data/raw"))
EXPECTED_FILES = {
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
}

def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def find_csv_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.csv") if path.is_file())

def copy_dataset_files(source_dir: Path, target_dir: Path) -> list[Path]:
    target_dir.mkdir(parents=True, exist_ok=True)
    copied: list[Path] = []
    for source_file in find_csv_files(source_dir):
        target_file = target_dir / source_file.name
        shutil.copy2(source_file, target_file)
        copied.append(target_file)
    return copied

def validate_files(csv_files: list[Path]) -> None:
    found = {path.name for path in csv_files}
    missing = EXPECTED_FILES - found
    unexpected = found - EXPECTED_FILES
    if missing:
        raise RuntimeError(
            "Arquivos esperados não encontrados: " + ", ".join(sorted(missing))
        )
    if unexpected:
        print(
            "Aviso: arquivos CSV adicionais encontrados: "
            + ", ".join(sorted(unexpected))
        )

def write_manifest(csv_files: list[Path]) -> Path:
    manifest = {
        "dataset_handle": DATASET_HANDLE,
        "downloaded_at_utc": datetime.now(timezone.utc).isoformat(),
        "file_count": len(csv_files),
        "files": [
            {
                "name": path.name,
                "size_bytes": path.stat().st_size,
                "sha256": sha256sum(path),
            }
            for path in csv_files
        ],
    }
    manifest_path = RAW_DATA_DIR / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return manifest_path

def download_dataset(force: bool = False) -> None:
    RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
    if force:
        for path in RAW_DATA_DIR.glob("*.csv"):
            path.unlink()
        manifest_path = RAW_DATA_DIR / "manifest.json"
        if manifest_path.exists():
            manifest_path.unlink()
    existing_files = sorted(RAW_DATA_DIR.glob("*.csv"))
    if existing_files and not force:
        print(f"Arquivos existentes encontrados em {RAW_DATA_DIR}; validando sem baixar novamente.")
        validate_files(existing_files)
        manifest_path = write_manifest(existing_files)
        print(f"Manifesto atualizado: {manifest_path}")
        return
    print(f"Baixando dataset: {DATASET_HANDLE}")
    cache_path = Path(kagglehub.dataset_download(DATASET_HANDLE))
    print(f"Dataset baixado no cache: {cache_path}")
    csv_files = copy_dataset_files(cache_path, RAW_DATA_DIR)
    if not csv_files:
        raise RuntimeError(f"Nenhum CSV encontrado em {cache_path}")
    validate_files(csv_files)
    manifest_path = write_manifest(csv_files)
    print(f"Arquivos copiados para: {RAW_DATA_DIR}")
    print(f"Manifesto criado em: {manifest_path}")
    print(f"Quantidade de CSVs: {len(csv_files)}")
    for path in csv_files:
        print(f"  - {path.name}: {path.stat().st_size / 1024 / 1024:.2f} MB")

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Baixa e valida o dataset Player Scores do Kaggle."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Força um novo download e substitui os CSVs existentes.",
    )
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    download_dataset(force=args.force)