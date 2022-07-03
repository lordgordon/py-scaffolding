# stage: baseline
FROM python:3.10-slim-bullseye AS base

ENV PIP_DEFAULT_TIMEOUT=100 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  PIP_NO_CACHE_DIR=1 \
  POETRY_NO_INTERACTION=1 \
  POETRY_VERSION=1.1.13 \
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  PYSETUP_PATH="/app" \
  PYTHONFAULTHANDLER=1 \
  PYTHONHASHSEED=random \
  PYTHONUNBUFFERED=1
ENV VENV_PATH="$PYSETUP_PATH/.venv"
ENV PATH="$VENV_PATH/bin:$PATH"

RUN mkdir $PYSETUP_PATH
WORKDIR $PYSETUP_PATH

# stage: builder (creates the .venv from poetry)
FROM base AS builder
RUN pip install -U pip "poetry==$POETRY_VERSION"

COPY pyproject.toml poetry.lock ./
RUN poetry install --no-dev

COPY py_scaffolding/ py_scaffolding/
COPY main.py .
RUN poetry build

ENTRYPOINT []
CMD []

# stage: production image
FROM base AS production
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
ENTRYPOINT ["python", "-OO", "main.py"]

# stage: vulnerability scanner on prod image
FROM production AS vulnscan
COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
ENTRYPOINT ["trivy"]

# stage: testing
FROM base AS testing
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH

RUN apt-get update && apt-get -y install --no-install-recommends make && rm -rf /var/lib/apt/lists/*
RUN pip install -U pip "poetry==$POETRY_VERSION"
RUN poetry install

COPY docs/ docs/
COPY tests/ tests/
COPY Makefile .

ENTRYPOINT [""]

# # stage: migrations
# FROM base as migrations
# COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
#
# RUN apt-get update \
#   && apt-get install -y --no-install-recommends postgresql-client \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*
#
# COPY migrations/ migrations/
# COPY alembic.ini .
#
# ENTRYPOINT ["./migrations/run_migrations.sh"]
