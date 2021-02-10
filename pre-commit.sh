#!/bin/sh

set -e;
pre-commit run --all-files;
make autolint;
make lint-mypy;
