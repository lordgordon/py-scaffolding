"""An example to show everything is working."""
from py_scaffolding.logging import set_up_logger

LOG = set_up_logger(logger_name=__name__)


def demo() -> int:
    """
    A very simple function to show docstrings with doctests are executed by pytest.

    Use this function like this:

    >>> demo()
    42
    """
    return 42


def demo_with_logger() -> None:
    """
    To test and demonstrate the use of logger.
    """
    LOG.info(
        "test log message",
        some_key="some value",
        another_key=True,
    )
