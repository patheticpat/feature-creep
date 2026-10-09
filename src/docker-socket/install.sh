#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

ensure_packages passwd

user="${_REMOTE_USER:-root}"
if [ "$user" = root ]; then
    log "remote user is root, socket access needs no group"
fi

# Entrypoints don't know the remote user: bake it in.
install -d /usr/local/share/feature-creep
sed "s|@REMOTE_USER@|$user|" "$(dirname "$0")/docker-socket-init.sh" \
    > /usr/local/share/feature-creep/docker-socket-init.sh
chmod 0755 /usr/local/share/feature-creep/docker-socket-init.sh
log "installed docker socket entrypoint for $user"

cleanup_apt
