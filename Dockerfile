# stage: baseline
ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE AS base

ARG PYSETUP_PATH
ENV PIP_DEFAULT_TIMEOUT=100 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  PIP_NO_CACHE_DIR=1 \
  POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  PYTHONFAULTHANDLER=1 \
  PYTHONHASHSEED=random \
  PYTHONUNBUFFERED=1 \
  LOCAL_USER=alice \
  POETRY_VERSION=1.3.1
ENV VENV_PATH="$PYSETUP_PATH/.venv"
ENV PATH="$VENV_PATH/bin:$PATH"

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

# stage: builder (creates the .venv from poetry)
FROM base AS builder
USER root
RUN pip install -U pip "poetry==$POETRY_VERSION"
USER $LOCAL_USER

COPY --chown=$LOCAL_USER:$LOCAL_USER pyproject.toml poetry.lock ./
RUN poetry install --no-dev

COPY --chown=$LOCAL_USER:$LOCAL_USER py_scaffolding/ py_scaffolding/
COPY --chown=$LOCAL_USER:$LOCAL_USER main.py .
COPY --chown=$LOCAL_USER:$LOCAL_USER LICENSE .
RUN poetry build

# stage: production image
FROM base AS production
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
ENTRYPOINT ["python", "-OO", "main.py"]

# stage: vulnerability scanner on prod image
FROM production AS vulnscan
COPY --from=aquasec/trivy:0.35.0 /usr/local/bin/trivy /usr/local/bin/trivy
ENTRYPOINT ["trivy"]

# stage: testing
FROM base AS testing
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH

USER root
RUN apt-get update && apt-get -y install --no-install-recommends make && rm -rf /var/lib/apt/lists/*
RUN pip install -U pip "poetry==$POETRY_VERSION"
RUN poetry install && \
    chown -R $LOCAL_USER:$LOCAL_USER $PYSETUP_PATH
USER $LOCAL_USER

COPY --chown=$LOCAL_USER:$LOCAL_USER docs/ docs/
COPY --chown=$LOCAL_USER:$LOCAL_USER tests/ tests/
COPY --chown=$LOCAL_USER:$LOCAL_USER Makefile .

# stage: migrations
FROM base as migrations
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH

USER root
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client && rm -rf /var/lib/apt/lists/*
USER $LOCAL_USER

# COPY --chown=$LOCAL_USER:$LOCAL_USER migrations/ migrations/
# COPY --chown=$LOCAL_USER:$LOCAL_USER alembic.ini .

# ENTRYPOINT ["./migrations/run_migrations.sh"]
