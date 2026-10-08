#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "jj runs" jj --version
check "config dir linked" bash -c '[ "$(readlink "$HOME/.config/jj")" = /usr/local/share/jj-host ]'

reportResults
