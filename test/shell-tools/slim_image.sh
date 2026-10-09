#!/usr/bin/env bash
# Slim image whose dpkg config drops all man pages.
set -e
source dev-container-features-test-lib

check "man pages no longer excluded" bash -c '! grep -rqE "^path-exclude[= ]/usr/share/man/" /etc/dpkg/dpkg.cfg.d/'
check "man ls" man -w ls
check "man grep" man -w grep
check "man of tool installed by the feature" man -w rg

reportResults
