from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://insurance_user:insurance_pass@db:5432/insurance_db"
    SECRET_KEY: str = "super-secret-key-change-in-production-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    UPLOAD_DIR: str = "/app/uploads"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024
    ALLOWED_EXTENSIONS: List[str] = ["pdf", "jpg", "jpeg", "png", "webp"]
    APP_NAME: str = "نظام إدارة التأمين الصحي"
    ALLOWED_ORIGINS: str = "http://localhost,http://localhost:3000,http://localhost:80"

    class Config:
        env_file = ".env"


settings = Settings()
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
