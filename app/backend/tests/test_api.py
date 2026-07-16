from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "platform-launchpad-api"}


def test_readiness() -> None:
    response = client.get("/api/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_info_schema_is_non_sensitive() -> None:
    response = client.get("/api/info")
    assert response.status_code == 200
    assert set(response.json()) == {
        "service_name",
        "version",
        "git_sha",
        "environment",
        "server_timestamp",
        "python_version",
        "status",
    }
    assert response.json()["status"] == "operational"


def test_generates_request_id() -> None:
    response = client.get("/api/health")
    assert len(response.headers["x-request-id"]) == 36


def test_propagates_request_id() -> None:
    response = client.get("/api/health", headers={"x-request-id": "correlation-123"})
    assert response.headers["x-request-id"] == "correlation-123"
