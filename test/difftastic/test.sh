#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "difft runs" difft --version

reportResults
