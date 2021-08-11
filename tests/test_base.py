"""A very simple test suite to test the proper setup."""

from faker import Faker
from hypothesis import given
from hypothesis import strategies as st

from py_scaffolding import __title__


def test_working():
    """Just to test everything is running as expected."""
    assert __title__ == "py-scaffolding"


@given(st.integers(), st.integers())
def test_ints_are_commutative(x, y):
    """Test hypotesis is running."""
    assert x + y == y + x


def test_faker():
    """Just an example on using Faker."""
    fake = Faker()  # type: ignore[no-untyped-call]
    Faker.seed(42)  # type: ignore[no-untyped-call]
    assert "@" in fake.ascii_company_email()
