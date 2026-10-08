# shellcheck shell=bash
# Shared helpers for feature install scripts.
# Canonical copy lives in lib/; scripts/sync-lib.sh copies it into every
# src/<feature>/ because published features cannot share files.

set -euo pipefail

log() { echo "[feature-creep] $*"; }
fail() { echo "[feature-creep] ERROR: $*" >&2; exit 1; }

# Install the given apt packages if any of them are missing.
ensure_packages() {
    local missing=()
    for pkg in "$@"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    [ "${#missing[@]}" -eq 0 ] && return 0
    command -v apt-get >/dev/null || fail "apt-get not found; only Debian/Ubuntu images are supported"
    log "apt-get install ${missing[*]}"
    export DEBIAN_FRONTEND=noninteractive
    if [ -z "$(find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -name '*_Packages' 2>/dev/null | head -1)" ]; then
        apt-get update -y
    fi
    apt-get install -y --no-install-recommends "${missing[@]}"
}

cleanup_apt() {
    rm -rf /var/lib/apt/lists/*
}

# Prints x86_64 or aarch64.
detect_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo x86_64 ;;
        aarch64 | arm64) echo aarch64 ;;
        *) fail "unsupported architecture: $(uname -m)" ;;
    esac
}

# Prints the latest release tag of a GitHub repo (owner/name) without using
# the rate-limited API: follows the /releases/latest redirect.
github_latest_tag() {
    local url
    url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")"
    [ "${url##*/}" != "latest" ] || fail "could not resolve latest release of $1"
    echo "${url##*/}"
}

# Prints the latest release tag of a Codeberg/Forgejo repo (owner/name).
codeberg_latest_tag() {
    curl -fsSL "https://codeberg.org/api/v1/repos/$1/releases/latest" \
        | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4
}

# install_from_tarball <url> <binary> [<binary>...]
# Downloads a .tar.gz, finds the named binaries anywhere inside and installs
# them to /usr/local/bin.
install_from_tarball() {
    local url="$1"
    shift
    local tmp
    tmp="$(mktemp -d)"
    log "downloading $url"
    curl -fsSL "$url" -o "$tmp/archive.tar.gz"
    tar -xzf "$tmp/archive.tar.gz" -C "$tmp"
    local bin path
    for bin in "$@"; do
        path="$(find "$tmp" -type f -name "$bin" | head -1)"
        [ -n "$path" ] || fail "$bin not found in $url"
        install -m 0755 "$path" "/usr/local/bin/$bin"
        log "installed /usr/local/bin/$bin"
    done
    rm -rf "$tmp"
}
