#!/bin/sh
# Container entrypoint: prepare the database, apply migrations, start the API.
set -e

cd /app/backend

python -m scripts.prepare_db
python -m alembic upgrade head

exec python -m uvicorn app.main:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --proxy-headers \
  --forwarded-allow-ips="*"
