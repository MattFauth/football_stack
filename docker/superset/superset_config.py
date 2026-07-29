from __future__ import annotations

import os
from urllib.parse import quote_plus

from cachelib.redis import RedisCache


def required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Variável obrigatória ausente: {name}")
    return value


SECRET_KEY = required_env("SUPERSET_SECRET_KEY")

DB_HOST = os.getenv("SUPERSET_DB_HOST", "superset-db")
DB_PORT = int(os.getenv("SUPERSET_DB_PORT", "5432"))
DB_NAME = os.getenv("SUPERSET_DB_NAME", "superset")
DB_USER = os.getenv("SUPERSET_DB_USER", "superset")
DB_PASSWORD = required_env("SUPERSET_DB_PASSWORD")

SQLALCHEMY_DATABASE_URI = (
    "postgresql+psycopg2://"
    f"{quote_plus(DB_USER)}:{quote_plus(DB_PASSWORD)}"
    f"@{DB_HOST}:{DB_PORT}/{quote_plus(DB_NAME)}"
)

SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_ENGINE_OPTIONS = {
    "pool_pre_ping": True,
    "pool_recycle": 300,
    "pool_size": 10,
    "max_overflow": 20,
}

REDIS_HOST = os.getenv("SUPERSET_REDIS_HOST", "superset-redis")
REDIS_PORT = int(os.getenv("SUPERSET_REDIS_PORT", "6379"))
REDIS_PASSWORD = required_env("SUPERSET_REDIS_PASSWORD")
REDIS_AUTH = quote_plus(REDIS_PASSWORD)
REDIS_BASE_URL = f"redis://:{REDIS_AUTH}@{REDIS_HOST}:{REDIS_PORT}"


def redis_cache(db: int, key_prefix: str, timeout: int = 86400) -> dict[str, object]:
    return {
        "CACHE_TYPE": "RedisCache",
        "CACHE_REDIS_URL": f"{REDIS_BASE_URL}/{db}",
        "CACHE_DEFAULT_TIMEOUT": timeout,
        "CACHE_KEY_PREFIX": key_prefix,
    }


# Bancos Redis separados evitam colisões entre finalidades.
FILTER_STATE_CACHE_CONFIG = redis_cache(2, "superset_filter_state_")
EXPLORE_FORM_DATA_CACHE_CONFIG = redis_cache(3, "superset_explore_form_")
DATA_CACHE_CONFIG = redis_cache(4, "superset_chart_data_", timeout=3600)
CACHE_CONFIG = redis_cache(5, "superset_metadata_", timeout=3600)

RESULTS_BACKEND = RedisCache(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    db=1,
    key_prefix="superset_sql_lab_results_",
    default_timeout=86400,
)
RESULTS_BACKEND_USE_MSGPACK = True


class CeleryConfig:
    broker_url = f"{REDIS_BASE_URL}/0"
    result_backend = f"{REDIS_BASE_URL}/1"
    imports = (
        "superset.sql_lab",
        "superset.tasks.scheduler",
    )
    worker_prefetch_multiplier = 1
    task_acks_late = True
    task_track_started = True
    broker_connection_retry_on_startup = True
    task_annotations = {
        "sql_lab.get_sql_results": {
            "rate_limit": "100/s",
        }
    }


CELERY_CONFIG = CeleryConfig

# Configuração web segura para ambiente local/containerizado.
ENABLE_PROXY_FIX = True
WTF_CSRF_ENABLED = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_SECURE = os.getenv("SUPERSET_COOKIE_SECURE", "false").lower() == "true"

# O chart Handlebars compila os templates no navegador e, por isso, requer
# 'unsafe-eval'. Mantemos as demais diretivas padrão do Superset explícitas.
TALISMAN_CONFIG = {
    "content_security_policy": {
        "base-uri": ["'self'"],
        "default-src": ["'self'"],
        "img-src": [
            "'self'",
            "blob:",
            "data:",
            "https://apachesuperset.gateway.scarf.sh",
            "https://static.scarf.sh/",
            "ows.terrestris.de",
            "https://cdn.document360.io",
            "https://tmssl.akamaized.net",
        ],
        "worker-src": ["'self'", "blob:"],
        "connect-src": [
            "'self'",
            "https://api.mapbox.com",
            "https://events.mapbox.com",
            "https://tile.openstreetmap.org",
            "https://tile.osm.ch",
        ],
        "object-src": "'none'",
        "style-src": ["'self'", "'unsafe-inline'"],
        "script-src": ["'self'", "'strict-dynamic'", "'unsafe-eval'"],
    },
    "content_security_policy_nonce_in": ["script-src"],
    "force_https": False,
    "session_cookie_secure": SESSION_COOKIE_SECURE,
}

# O SQL Lab pode usar o worker Celery quando a conexão for marcada como assíncrona.
# Os charts Handlebars deste ambiente são mantidos por usuários confiáveis e
# precisam renderizar HTML e CSS sem que o sanitizador desmonte o template.
# Não reutilizar esta configuração em uma instância pública/multiusuário.
HTML_SANITIZATION = False

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

# Limites sensatos para exploração local. Podem ser sobrescritos depois.
ROW_LIMIT = int(os.getenv("SUPERSET_ROW_LIMIT", "50000"))
SQL_MAX_ROW = int(os.getenv("SUPERSET_SQL_MAX_ROW", "100000"))
SUPERSET_WEBSERVER_TIMEOUT = int(os.getenv("SUPERSET_WEBSERVER_TIMEOUT", "120"))

# Evita carregamento acidental de dados de exemplo.
SUPERSET_LOAD_EXAMPLES = False
