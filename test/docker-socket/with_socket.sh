#!/usr/bin/env bash
# Container runs as a non-root user (entrypoint uses sudo) with the host's
# docker socket mounted.
set -e
source dev-container-features-test-lib

check "socket mounted" test -S /var/run/docker.sock
check "user in socket's group" bash -c 'getent group "$(stat -c %g /var/run/docker.sock)" | cut -d: -f4 | tr , "\n" | grep -qx vscode'

reportResults
