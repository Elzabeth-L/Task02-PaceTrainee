#!/usr/bin/env bash
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}/app/backend"
python -m pip install --disable-pip-version-check -r requirements-dev.txt
ruff check .
ruff format --check .
mypy app
pytest
