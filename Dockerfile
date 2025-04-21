# stage: baseline
ARG DOCKER_BASE_IMAGE="python:3.11.12-slim-bullseye"
ARG TRIVY_DOCKER_IMAGE="aquasec/trivy:0.61.1"

FROM $TRIVY_DOCKER_IMAGE AS trivy

FROM $DOCKER_BASE_IMAGE AS base
  ARG PYSETUP_PATH="/app"
  ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1 \
    UV_LOCKED=1 \
    UV_PYTHON_PREFERENCE="system" \
    LOCAL_USER=alice
  ENV VIRTUAL_ENV="$PYSETUP_PATH/.venv"
  ENV PATH="$VIRTUAL_ENV/bin:$PATH"

  # create non root user
  RUN mkdir $PYSETUP_PATH && \
      groupadd --system $LOCAL_USER && \
      useradd --no-log-init --create-home --system --shell /bin/bash -g $LOCAL_USER $LOCAL_USER && \
      chown $LOCAL_USER:$LOCAL_USER $PYSETUP_PATH

  # update the base image to latest security fixes and tools
  RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/* && \
      /usr/local/bin/python3 -m pip install --upgrade setuptools pip

  WORKDIR $PYSETUP_PATH
  USER $LOCAL_USER
  ENTRYPOINT []
  CMD []

# stage: builder (creates the .venv from uv)
FROM base AS builder
  USER root
  COPY --from=ghcr.io/astral-sh/uv:0.6.14 /uv /uvx /bin/

  USER $LOCAL_USER
  COPY --chown=$LOCAL_USER:$LOCAL_USER pyproject.toml uv.lock ./
  COPY --chown=$LOCAL_USER:$LOCAL_USER src/ src/
  COPY --chown=$LOCAL_USER:$LOCAL_USER main.py .
  COPY --chown=$LOCAL_USER:$LOCAL_USER LICENSE .
  COPY --chown=$LOCAL_USER:$LOCAL_USER README.md .

  RUN uv sync --no-dev --inexact --no-editable

# stage: production image
FROM base AS production
  COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
  ENTRYPOINT ["python", "-I", "-OO", "main.py"]

# stage: vulnerability scanner on prod image
FROM production AS vulnscan
  COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy
  ENTRYPOINT ["trivy"]

# stage: testing
FROM base AS testing
  USER root
  COPY --from=builder /bin/uv /bin/uvx /bin/
  COPY --from=builder --chown=$LOCAL_USER:$LOCAL_USER $PYSETUP_PATH $PYSETUP_PATH
  RUN apt-get update && apt-get -y install --no-install-recommends make && rm -rf /var/lib/apt/lists/*

  USER $LOCAL_USER
  RUN uv sync --inexact --no-editable

  COPY --chown=$LOCAL_USER:$LOCAL_USER docs/ docs/
  COPY --chown=$LOCAL_USER:$LOCAL_USER tests/ tests/
  COPY --chown=$LOCAL_USER:$LOCAL_USER Makefile .

# stage: migrations
FROM base AS migrations
  COPY --from=builder --chown=$LOCAL_USER:$LOCAL_USER $PYSETUP_PATH $PYSETUP_PATH

  USER root
  RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client && rm -rf /var/lib/apt/lists/*
  USER $LOCAL_USER

  # COPY --chown=$LOCAL_USER:$LOCAL_USER migrations/ migrations/
  # COPY --chown=$LOCAL_USER:$LOCAL_USER alembic.ini .

  # ENTRYPOINT ["./migrations/run_migrations.sh"]
