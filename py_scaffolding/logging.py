"""
Configure the logger with a structured JSON log format.
"""
from __future__ import annotations

import logging
import sys

import structlog


def set_up_logger(
    *, logger_name: str, log_level: int = logging.INFO
) -> structlog.stdlib.BoundLogger:
    """
    Setup the logger object to use in your code.

    ..  code-block:: python
        :caption: Minimal example

        from applications_processing.helpers.logging import set_up_logger
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
    logger = structlog.get_logger(logger_name)
    logger.setLevel(log_level)
    if not logger.new()._logger.handlers:  # pragma: no cover
        logger.addHandler(_configure_logger_handlers())
    return logger


def _configure_logger_handlers() -> logging.StreamHandler:
    """ Internal helper to add handlers. """
    logger_handler = logging.StreamHandler(sys.stdout)
    return logger_handler


def _set_up_structlog() -> None:
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
        context_class=structlog.threadlocal.wrap_dict(dict),
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
