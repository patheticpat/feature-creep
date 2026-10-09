#!/bin/sh
# Runs on every container start as feature entrypoint. Must not block, exec or
# fail: it is one line in the devcontainer CLI's entrypoint chain.
#
# The GID owning the host's docker socket differs per host, so the matching
# group can only be set up at start, not baked into the image.

sock=/var/run/docker.sock
user=@REMOTE_USER@

log() { echo "[feature-creep] docker-socket: $*"; }

[ -S "$sock" ] || exit 0
[ "$user" != root ] || exit 0

# Entrypoints run as the container user, which is not always root.
if [ "$(id -u)" = 0 ]; then
    as_root() { "$@"; }
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    as_root() { sudo -n "$@"; }
else
    log "neither root nor passwordless sudo, not touching groups"
    exit 0
fi

gid="$(stat -c %g "$sock")"
if [ "$gid" = 0 ]; then
    # e.g. Docker Desktop: never hand out the root group.
    log "socket belongs to GID 0, not adding $user to it"
    exit 0
fi

group="$(getent group "$gid" | cut -d: -f1)"
if [ -z "$group" ]; then
    group=docker-host
    if getent group "$group" >/dev/null; then
        as_root groupmod -g "$gid" "$group" || exit 0
    else
        as_root groupadd -g "$gid" "$group" || exit 0
    fi
fi

if id -nG "$user" | tr ' ' '\n' | grep -qx "$group"; then
    exit 0
fi
as_root usermod -aG "$group" "$user" && log "added $user to $group (GID $gid)"
exit 0
