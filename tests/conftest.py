"""Common PyTest setup."""

# pylint: disable=missing-function-docstring

import json
import logging
from collections.abc import Iterator, Sequence
from io import StringIO

import pytest


class JSONLogIO(StringIO):
    """Helper to capture logs and convert the raw JSON string into a proper dict."""

    def __init__(self, initial_value: str | None = None, newline: str | None = None) -> None:
        super().__init__(initial_value=initial_value, newline=newline)
        self._entries: Sequence[dict] = []

    @property
    def entries(self) -> Sequence[dict]:
        # build _entries only once
        if not self._entries:
            self._entries = [json.loads(line) for line in self.getvalue().splitlines()]

        return self._entries


@pytest.fixture
def log_capture() -> Iterator[JSONLogIO]:
    """To capture our custom logger based on structlog."""
    logger = logging.getLogger()

    # we need a custom handler
    buffer = JSONLogIO()
    log_handler = logging.StreamHandler(buffer)
    logger.addHandler(log_handler)

    yield buffer

    # teardown
    logger.removeHandler(log_handler)
