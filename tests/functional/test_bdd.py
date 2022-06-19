"""BDD example."""

import random

import pytest
from pytest_bdd import given, parsers, scenarios, then

scenarios("features/test.feature")


@pytest.fixture
def scenario_context() -> dict:
    return {}


@given(parsers.parse("{var} a random integer"))  # type: ignore[misc]
def start_scenario(scenario_context: dict, var: int) -> dict:
    """Set up the scenario."""
    scenario_context[var] = random.randrange(1000)
    return scenario_context


@then(parsers.parse("{var_x} + {var_y} is commutative (x + y = y + x)"))  # type: ignore[misc]
def scenario_result(scenario_context: dict, var_x: int, var_y: int) -> None:
    """Check the result."""
    assert (
        scenario_context[var_x] + scenario_context[var_y]
        == scenario_context[var_y] + scenario_context[var_x]
    )
