import logging
import platform
import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.logging import configure_logging
from app.models import ErrorResponse, HealthResponse, InfoResponse

settings = get_settings()
configure_logging(settings.log_level)
logger = logging.getLogger("platform_api")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    logger.info("application_started")
    yield
    logger.info("application_stopped")


app = FastAPI(
    title="Platform Launchpad API",
    version=settings.app_version,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    lifespan=lifespan,
)


@app.middleware("http")
async def request_observability(request: Request, call_next):  # type: ignore[no-untyped-def]
    request_id = request.headers.get("x-request-id", "").strip()[:128] or str(uuid.uuid4())
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception("unhandled_exception", extra={"request_id": request_id})
        error = ErrorResponse(detail="Internal server error", request_id=request_id)
        response = JSONResponse(status_code=500, content=error.model_dump())
    duration_ms = round((time.perf_counter() - started) * 1000, 2)
    response.headers["x-request-id"] = request_id
    logger.info(
        "request_completed",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response


@app.get("/api/health", response_model=HealthResponse, status_code=200)
async def health() -> HealthResponse:
    return HealthResponse(status="healthy", service=settings.service_name)


@app.get("/api/ready", response_model=HealthResponse, status_code=200)
async def ready() -> HealthResponse:
    return HealthResponse(status="ready", service=settings.service_name)


@app.get("/api/info", response_model=InfoResponse, status_code=200)
async def info() -> InfoResponse:
    return InfoResponse(
        service_name=settings.service_name,
        version=settings.app_version,
        git_sha=settings.git_sha,
        environment=settings.environment,
        server_timestamp=datetime.now(UTC),
        python_version=platform.python_version(),
        status="operational",
    )
