# ORCA backend image. Build from the repository root so the trained
# habitat model in ml/artifacts is included:
#   docker build -f backend/Dockerfile -t orca-backend .
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY backend/requirements.txt backend/requirements.txt
RUN pip install -r backend/requirements.txt

COPY backend/ backend/
COPY ml/artifacts/ ml/artifacts/

RUN sed -i 's/\r$//' backend/scripts/start.sh && chmod +x backend/scripts/start.sh

EXPOSE 8000

CMD ["/app/backend/scripts/start.sh"]
