# hadolint global ignore=DL3008
#   DL3008: Pin versions in apt get install

# stage: baseline
ARG DOCKER_BASE_IMAGE="python:3.14.2-slim-trixie"
ARG UV_VERSION="0.9.2"
ARG UV_BASE_IMAGE="ghcr.io/astral-sh/uv:${UV_VERSION}"

FROM $UV_BASE_IMAGE AS uv

FROM $DOCKER_BASE_IMAGE AS base
ARG PYSETUP_PATH="/app"

# Debian settings
ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  TZ=UTC \
  DEBIAN_FRONTEND=noninteractive
# Python and pip
ENV PIP_DEFAULT_TIMEOUT=100 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  PIP_NO_CACHE_DIR=1 \
  PYTHONFAULTHANDLER=1 \
  PYTHONHASHSEED=random \
  PYTHONUNBUFFERED=1
# uv settings
#   - UV_LOCKED: uv.lock must remain unchanged in the container and fails to install when it is outdated.
#   - UV_NO_SYNC: don't try to sync at every uv run. Implies UV_FROZEN.
ENV UV_LOCKED=1 \
  UV_NO_SYNC=1 \
  UV_PYTHON_PREFERENCE="system"
# other settings
ENV LOCAL_USER=alice \
  VIRTUAL_ENV="$PYSETUP_PATH/.venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# create non root user
RUN mkdir $PYSETUP_PATH && \
    groupadd --system $LOCAL_USER && \
    useradd --no-log-init --create-home --system --shell /bin/bash -g $LOCAL_USER $LOCAL_USER && \
    chown $LOCAL_USER:$LOCAL_USER $PYSETUP_PATH

# update the base image to latest security fixes and tools, add required packages to build Python packages
RUN apt-get update && \
    apt-get -y upgrade &&  \
    # for uvloop
    apt-get -y install --no-install-recommends build-essential gcc python3-dev libuv1-dev && \
    rm -rf /var/lib/apt/lists/* && \
    /usr/local/bin/python3 -m pip install --upgrade setuptools pip

WORKDIR $PYSETUP_PATH
USER $LOCAL_USER
ENTRYPOINT []
CMD []

# stage: builder (creates the .venv from uv)
FROM base AS builder
USER root
COPY --from=uv /uv /uvx /bin/

USER $LOCAL_USER
COPY --chown=$LOCAL_USER:$LOCAL_USER pyproject.toml uv.lock ./
RUN uv sync --no-dev --inexact --no-editable

COPY --chown=$LOCAL_USER:$LOCAL_USER src/ src/
COPY --chown=$LOCAL_USER:$LOCAL_USER main.py .
COPY --chown=$LOCAL_USER:$LOCAL_USER LICENSE .
COPY --chown=$LOCAL_USER:$LOCAL_USER README.md .

# stage: production image
FROM base AS production
COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
ENTRYPOINT ["python", "-I", "-OO", "main.py"]

# stage: testing
FROM base AS testing
USER root

ENV RUNNING_IN_DOCKER=true

COPY --from=builder /bin/uv /bin/uvx /bin/
COPY --from=builder --chown=$LOCAL_USER:$LOCAL_USER $PYSETUP_PATH $PYSETUP_PATH

RUN apt-get update && \
    apt-get -y install --no-install-recommends make curl && \
    rm -rf /var/lib/apt/lists/*

USER $LOCAL_USER
RUN uv sync

COPY --chown=$LOCAL_USER:$LOCAL_USER docs/ docs/
COPY --chown=$LOCAL_USER:$LOCAL_USER tests/ tests/
COPY --chown=$LOCAL_USER:$LOCAL_USER Makefile .
