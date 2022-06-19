"""A very simple test suite to test the proper setup."""

from faker import Faker
from hypothesis import given
from hypothesis import strategies as st

from py_scaffolding import __title__
from py_scaffolding.example import demo_with_logger

from .conftest import JSONLogIO


def test_working() -> None:
    """Just to test everything is running as expected."""
    assert __title__ == "py-scaffolding"


@given(st.integers(), st.integers())
def test_ints_are_commutative(x: int, y: int) -> None:
    """Test hypotesis is running."""
    assert x + y == y + x


def test_faker() -> None:
    """Just an example on using Faker."""
    fake = Faker()
    Faker.seed(42)
    assert "@" in fake.ascii_company_email()


def test_structlog_capture(log_capture: JSONLogIO) -> None:
    """Ensures our custom logger capture works and the captured log has the minimal expected keys."""
    demo_with_logger()

    assert len(log_capture.entries) == 1
    logged_entry = log_capture.entries[0]
    assert isinstance(logged_entry, dict)
    assert "level" in logged_entry
    assert "event" in logged_entry
    assert "timestamp" in logged_entry


def test_demo_with_logger(log_capture: JSONLogIO) -> None:
    """An example on how to test the logger."""
    assert log_capture.entries == []

    demo_with_logger()

    assert len(log_capture.entries) == 1
    logged_entry = log_capture.entries[0]
    assert logged_entry["level"] == "info"
    assert logged_entry["event"] == "test log message"
    assert logged_entry["some_key"] == "some value"
    assert logged_entry["another_key"]
