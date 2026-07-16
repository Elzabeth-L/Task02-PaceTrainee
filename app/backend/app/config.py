from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    service_name: str = "platform-launchpad-api"
    app_version: str = "1.0.0"
    git_sha: str = "development"
    environment: str = "local"
    log_level: str = "INFO"
    model_config = SettingsConfigDict(env_prefix="", case_sensitive=False)


@lru_cache
def get_settings() -> Settings:
    return Settings()
