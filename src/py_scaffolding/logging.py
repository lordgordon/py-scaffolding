"""
Configure the logger with a structured JSON log format.
"""

import logging
import sys
from typing import cast

import structlog


def set_up_logger(
    *,
    logger_name: str,
    log_level: int = logging.INFO,
) -> structlog.stdlib.BoundLogger:  # pragma: no cover
    """
    Set up the logger object to use in your code.

    ..  code-block:: python
        :caption: Minimal example

        from py_scaffolding.logging import set_up_logger
        LOG = set_up_logger(logger_name=__name__)

        # ... later in the code ...
        LOG.info(
            "log message",
            some_key="some value",
            another_key=True,
        )
    """
    # pylint: disable=protected-access
    _set_up_structlog()
    logger = cast(structlog.stdlib.BoundLogger, structlog.get_logger(logger_name))
    logger.setLevel(log_level)
    if not logger.new()._logger.handlers:
        logger.addHandler(_configure_logger_handlers())
    return logger


def set_logger_level(
    *,
    logger: structlog.stdlib.BoundLogger,
    level: str,
) -> None:  # pragma: no cover
    """
    Allow to set a new logging level by name for an existing logger.

    ..  code-block:: python
        :caption: Minimal example

        from py_scaffolding.logging import set_logger_level

        # ... in the entry point ...
        set_logger_level(logger=LOG, level="DEBUG")
    """
    # NOTE: level is not further refined with a Literal of allowed strings due to the dynamic nature of logging levels.
    clean_level = level.upper()
    numeric_level = getattr(logging, clean_level)
    logger.setLevel(numeric_level)
    logger.info(
        "Log level changed", new_level=clean_level, new_level_numeric=numeric_level
    )


def _configure_logger_handlers() -> logging.StreamHandler:  # pragma: no cover
    """Internal helper to add handlers."""
    logger_handler = logging.StreamHandler(sys.stdout)
    return logger_handler


def _set_up_structlog() -> None:  # pragma: no cover
    """
    Internal helper to configure structlog.

    For further details look at https://www.structlog.org/en/stable/
    """
    if structlog.is_configured():  # pragma: no cover
        return

    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_log_level,
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(sort_keys=False),
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
