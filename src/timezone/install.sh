#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

ensure_packages tzdata

install -D -m 0755 "$(dirname "$0")/timezone-init.sh" /usr/local/share/feature-creep/timezone-init.sh

cleanup_apt
