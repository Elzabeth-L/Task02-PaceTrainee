from datetime import datetime

from pydantic import BaseModel, ConfigDict


class HealthResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: str
    service: str


class InfoResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    service_name: str
    version: str
    git_sha: str
    environment: str
    server_timestamp: datetime
    python_version: str
    status: str


class ErrorResponse(BaseModel):
    detail: str
    request_id: str
