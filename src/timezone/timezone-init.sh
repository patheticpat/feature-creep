#!/bin/sh
# Runs on every container start as feature entrypoint. Must not block, exec or
# fail: it is one line in the devcontainer CLI's entrypoint chain.
#
# Finds the zone name matching the host's /etc/localtime (mounted read-only),
# so tools that need a name (ICU: Node, Java) see e.g. Europe/Berlin, not UTC.

src=/usr/local/share/host-localtime
zoneinfo=/usr/share/zoneinfo

log() { echo "[feature-creep] timezone: $*"; }

if [ ! -f "$src" ]; then
    log "host /etc/localtime not mounted, keeping container time zone"
    exit 0
fi
# Entrypoints run as the container user, which is not always root.
if [ "$(id -u)" = 0 ]; then
    as_root() { "$@"; }
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    as_root() { sudo -n "$@"; }
else
    log "neither root nor passwordless sudo, keeping container time zone"
    exit 0
fi

matches="$(cd "$zoneinfo" 2>/dev/null && find . -type f \
    ! -path './posix/*' ! -path './right/*' ! -name posixrules \
    -exec cmp -s "$src" {} \; -print | sed 's|^\./||' | sort)"

# Identical files can exist under several names; prefer a canonical zone
# ("Z" line in tzdata.zi) over a link.
name=""
for m in $matches; do
    if awk -v n="$m" '$1 == "Z" && $2 == n { found = 1 } END { exit !found }' "$zoneinfo/tzdata.zi" 2>/dev/null; then
        name="$m"
        break
    fi
done
[ -n "$name" ] || name="$(echo "$matches" | head -n 1)"

# /etc/localtime is usually a symlink into zoneinfo: remove it first, never
# write through it.
as_root rm -f /etc/localtime
if [ -n "$name" ]; then
    as_root ln -s "$zoneinfo/$name" /etc/localtime
    echo "$name" | as_root tee /etc/timezone >/dev/null
    log "set to $name"
else
    # Host and container tzdata differ: still get the right local time.
    as_root cp "$src" /etc/localtime
    as_root rm -f /etc/timezone
    log "no matching zone name found, copied host /etc/localtime"
fi
exit 0
