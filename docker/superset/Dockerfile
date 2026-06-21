# syntax=docker/dockerfile:1.7

ARG SUPERSET_VERSION=6.0.0
FROM apache/superset:${SUPERSET_VERSION}

USER root

# A imagem lean do Superset não traz os drivers do metastore nem do
# banco analítico. Fixamos as versões para manter a build reproduzível.
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
      psycopg2-binary==2.9.12 \
      redis==7.3.0 \
      duckdb==1.5.4 \
      duckdb-engine==0.17.0

COPY --chown=superset:superset docker/superset/superset_config.py /app/pythonpath/superset_config.py
COPY --chown=superset:superset docker/superset/init.sh /app/docker/init.sh

RUN chmod 0555 /app/docker/init.sh \
    && chmod 0444 /app/pythonpath/superset_config.py

ENV SUPERSET_CONFIG_PATH=/app/pythonpath/superset_config.py \
    PYTHONPATH=/app/pythonpath

USER superset
