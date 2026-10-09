#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

# The test container has no docker socket: only check the entrypoint is sane.
check "entrypoint installed" test -x /usr/local/share/feature-creep/docker-socket-init.sh
check "remote user baked in" bash -c '! grep -q @REMOTE_USER@ /usr/local/share/feature-creep/docker-socket-init.sh'
check "entrypoint succeeds without socket" /usr/local/share/feature-creep/docker-socket-init.sh

reportResults
