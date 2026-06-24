# syntax=docker/dockerfile:1.7

ARG PYTHON_VERSION=3.12.13
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG APP_UID=10001
ARG APP_GID=10001

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/home/app/.local/bin:${PATH}"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        make \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${APP_GID}" app \
    && useradd \
        --uid "${APP_UID}" \
        --gid "${APP_GID}" \
        --create-home \
        --shell /bin/bash \
        app

WORKDIR /app

COPY requirements.txt /tmp/requirements.txt

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install --requirement /tmp/requirements.txt

RUN mkdir -p \
        /app/data/raw \
        /app/dbt \
        /app/scripts \
        /app/tests \
        /app/notebooks \
        /app/logs \
    && chown -R app:app /app /home/app

COPY --chown=app:app . /app

USER app

CMD ["bash"]
