"""A very simple test suite to test the proper setup."""

from hypothesis import given
from hypothesis import strategies as st

from src import __title__


def test_working():
    """Just to test everything is running as expected."""
    assert __title__ == "py-scaffolding"


@given(st.integers(), st.integers())
def test_ints_are_commutative(x, y):
    """Test hypotesis is running."""
    assert x + y == y + x
