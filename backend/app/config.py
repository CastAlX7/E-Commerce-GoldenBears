from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://postgres:1234@localhost:5432/golden_bears"
    SECRET_KEY: str = "BRE@ososdelmileniodorado123"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    GMAIL_USER: str = "stilesvcc@gmail.com"
    GMAIL_APP_PASSWORD: str = ""
    GMAIL_FROM_NAME: str = "Golden Bears"
    EMAIL_ENABLED: bool = True

    class Config:
        env_file = ".env"


settings = Settings()
