#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "host localtime mounted" test -f /usr/local/share/host-localtime
check "localtime matches host" cmp -s /etc/localtime /usr/local/share/host-localtime
date
cat /etc/timezone 2>/dev/null || echo "no /etc/timezone"

reportResults
