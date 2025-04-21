"""An example to show everything is working."""

from py_scaffolding.logging import set_logger_level, set_up_logger
from py_scaffolding.settings import Settings

LOG = set_up_logger(logger_name=__name__)


def demo() -> int:  # pragma: no cover
    """
    A very simple function to show docstrings with doctests are executed by pytest.

    Use this function like this:

    >>> demo()
    42
    """
    return 42


def demo_with_logger() -> None:  # pragma: no cover
    """
    To test and demonstrate the use of logger.
    """
    LOG.info(
        "test log message",
        some_key="some value",
        another_key=True,
    )


def example() -> None:  # pragma: no cover
    """A very basic example using the helpers provided by this scaffolding project."""
    settings = Settings()
    set_logger_level(logger=LOG, level=settings.LOG_LEVEL)

    demo_with_logger()
    print(demo())  # noqa: T201
