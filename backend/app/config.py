from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


# backend/.env, resolved from this file so it loads regardless of the working directory.
ENV_FILE = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    # Database: either a single DATABASE_URL (as provided by cloud hosts)
    # or the individual DB_* values used for local development.
    database_url: str | None = None
    db_host: str = "127.0.0.1"
    db_port: int = 5432
    db_name: str = "orca_db"
    db_user: str = "orca_app"
    db_password: str = ""

    # Authentication
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 90

    # Application
    app_env: str = "development"

    # OTP
    otp_expire_minutes: int = 5
    otp_resend_cooldown_seconds: int = 60

    # OTP delivery: "dev" (show code in app) or "sms_gate" (real SMS
    # via SMS Gateway for Android). See app/services/sms_service.py.
    otp_provider: str = "dev"
    sms_gate_url: str = "https://api.sms-gate.app/3rdparty/v1"
    sms_gate_username: str | None = None
    sms_gate_password: str | None = None

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()