# syntax=docker/dockerfile:1.7

ARG SUPERSET_VERSION=6.0.0
FROM apache/superset:${SUPERSET_VERSION}

USER root

RUN uv pip install \
      --python /app/.venv/bin/python \
      --no-cache \
      psycopg2-binary==2.9.12 \
      redis==7.3.0

COPY --chown=superset:superset \
    docker/superset/superset_config.py \
    /app/pythonpath/superset_config.py

COPY --chown=superset:superset \
    docker/superset/init.sh \
    /app/docker/init.sh

RUN chmod 0555 /app/docker/init.sh \
    && chmod 0444 /app/pythonpath/superset_config.py

ENV SUPERSET_CONFIG_PATH=/app/pythonpath/superset_config.py \
    PYTHONPATH=/app/pythonpath

USER superset
