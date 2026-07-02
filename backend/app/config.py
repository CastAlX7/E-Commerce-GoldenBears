from pydantic_settings import BaseSettings
from pydantic import model_validator


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://postgres:1234@localhost:5432/golden_bears"
    DB_HOST: str = ""
    DB_PORT: str = "5432"
    DB_USER: str = ""
    DB_PASSWORD: str = ""
    DB_NAME: str = ""

    SECRET_KEY: str = "BRE@ososdelmileniodorado123"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    GMAIL_USER: str = "stilesvcc@gmail.com"
    GMAIL_APP_PASSWORD: str = ""
    GMAIL_FROM_NAME: str = "Golden Bears"
    EMAIL_ENABLED: bool = True

    REDIS_HOST: str = ""
    REDIS_PORT: str = "6379"
    REDIS_AUTH_TOKEN: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"

    @model_validator(mode="after")
    def assemble_database_url(self):
        if self.DB_HOST:
            self.DATABASE_URL = (
                f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}"
                f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            )
        return self


settings = Settings()
