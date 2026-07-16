# syntax=docker/dockerfile:1.7
FROM python:3.14.6-slim-bookworm AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1
WORKDIR /build
COPY requirements.txt ./
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.14.6-slim-bookworm
ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown
ARG SOURCE_URL=unknown
ARG APP_VERSION=0.0.0
LABEL org.opencontainers.image.source=$SOURCE_URL \
      org.opencontainers.image.revision=$GIT_SHA \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.title="Platform Launchpad backend" \
      org.opencontainers.image.description="FastAPI service for the Platform Launchpad" \
      org.opencontainers.image.version=$APP_VERSION
ENV PATH="/opt/venv/bin:$PATH" PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    GIT_SHA=$GIT_SHA APP_VERSION=$APP_VERSION PORT=8000
RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app --home /app app
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=2)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--proxy-headers", "--no-access-log", "--timeout-graceful-shutdown", "30"]
