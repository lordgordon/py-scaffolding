"""Settings from environment."""

from typing import Literal

from pydantic_settings import BaseSettings


class Settings(BaseSettings):  # pragma: no cover
    """Set those variables in the environment."""

    LOG_LEVEL: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
