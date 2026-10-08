#!/usr/bin/env bash
# Resolves the dependsOn features from the registry, so they must be published.
set -e
source dev-container-features-test-lib

check "jj" jj --version
check "difft" difft --version
check "mergiraf" mergiraf --version
check "starship" starship --version
check "vim" vim --version

reportResults
