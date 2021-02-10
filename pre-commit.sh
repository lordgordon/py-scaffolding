#!/bin/sh

pre-commit run --all-files;
make autolint;

set -e;
make lint-mypy;
