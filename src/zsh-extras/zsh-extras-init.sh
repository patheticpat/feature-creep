#!/bin/sh
# Runs on every container start as feature entrypoint. Must not block, exec or
# fail: it is one line in the devcontainer CLI's entrypoint chain.
#
# The volume keeps the owner it got when first created. If the remote user's
# UID differs (another host, updateRemoteUserUID), hand it over.

dir=/usr/local/share/zsh-history
user=@REMOTE_USER@

log() { echo "[feature-creep] zsh-extras: $*"; }

[ -d "$dir" ] || exit 0
uid="$(id -u "$user" 2>/dev/null)" || exit 0
[ "$(stat -c %u "$dir")" != "$uid" ] || exit 0

# Entrypoints run as the container user, which is not always root.
if [ "$(id -u)" = 0 ]; then
    as_root() { "$@"; }
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    as_root() { sudo -n "$@"; }
else
    log "$dir is not owned by $user, but neither root nor passwordless sudo"
    exit 0
fi

as_root chown -R "$user:$(id -gn "$user")" "$dir" && log "handed $dir to $user"
exit 0
