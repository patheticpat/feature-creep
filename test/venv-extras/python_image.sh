#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

python3 -m venv /tmp/venvs/app
python3 -m venv /tmp/other
python3 -m venv --clear /tmp/venvs/app2

check "overlay visible in matching venv" /tmp/venvs/app/bin/python -c 'import pytest, pytest_django, IPython'
check "overlay visible in recreated venv" /tmp/venvs/app2/bin/python -c 'import pytest'
check "overlay is last on sys.path" /tmp/venvs/app/bin/python -c 'import sys; assert sys.path[-1] == "/usr/local/share/venv-extras/site", sys.path'
check "venv packages win" bash -c '/tmp/venvs/app/bin/pip install -q "pluggy==1.5.0" && /tmp/venvs/app/bin/python -c "import pluggy; assert pluggy.__version__ == \"1.5.0\", pluggy.__version__"'
check "not visible in other venv" bash -c '! /tmp/other/bin/python -c "import pytest"'
check "not visible in base python" bash -c '! python3 -c "import pytest"'
check "pytest-django plugin registered" bash -c 'cd /tmp && /tmp/venvs/app/bin/python -m pytest --version 2>&1 | grep -q . && /tmp/venvs/app/bin/python -m pytest --help | grep -q -- --reuse-db'
check "pytest wrapper uses active venv" bash -c 'source /tmp/venvs/app/bin/activate && pytest --version'
check "wrapper refuses outside venv" bash -c '! pytest --version'

reportResults
