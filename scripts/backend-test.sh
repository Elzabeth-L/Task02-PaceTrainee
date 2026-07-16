#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../app/backend"
python -m pip install -r requirements-dev.txt
ruff check .
ruff format --check .
mypy app
pytest
