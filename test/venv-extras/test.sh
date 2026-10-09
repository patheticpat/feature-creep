#!/usr/bin/env bash
# Default options: no packages, so nothing must be installed.
set -e
source dev-container-features-test-lib

check "no overlay without packages" test ! -e /usr/local/share/venv-extras

reportResults
