from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


# backend/.env, resolved from this file so it loads regardless of the working directory.
ENV_FILE = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    # Database
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str

    # Authentication
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # Application
    app_env: str = "development"

    # OTP
    otp_expire_minutes: int = 5
    otp_resend_cooldown_seconds: int = 60

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()