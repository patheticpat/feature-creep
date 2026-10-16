#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

arch="$(detect_arch)"

# git: lazy.nvim clones plugins; gcc + libc6-dev + tree-sitter CLI:
# nvim-treesitter builds its parsers; unzip: mason unpacks LSP servers.
packages=(curl ca-certificates tar gzip)
[ "${CONFIG:-true}" = "true" ] && packages+=(git unzip gcc libc6-dev)
ensure_packages "${packages[@]}"

# Distro packages are too old for LazyVim (needs >= 0.11.2): use the release
# tarball, a self-contained tree (bin/, lib/, share/).
version="${VERSION:-latest}"
case "$version" in
    latest) tag="$(github_latest_tag neovim/neovim)" ;;
    stable) tag=stable ;;
    *) tag="v${version#v}" ;;
esac

case "$arch" in
    x86_64) nvim_arch=x86_64 ts_arch=x64 ;;
    aarch64) nvim_arch=arm64 ts_arch=arm64 ;;
esac

tmp="$(mktemp -d)"
url="https://github.com/neovim/neovim/releases/download/${tag}/nvim-linux-${nvim_arch}.tar.gz"
log "downloading $url"
curl -fsSL "$url" -o "$tmp/nvim.tar.gz"
rm -rf /opt/nvim
mkdir -p /opt/nvim
tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
log "installed $(/opt/nvim/bin/nvim --version | head -1) to /opt/nvim"
rm -rf "$tmp"

[ "${CONFIG:-true}" = "true" ] || { cleanup_apt; exit 0; }

tag="$(github_latest_tag tree-sitter/tree-sitter)"
url="https://github.com/tree-sitter/tree-sitter/releases/download/${tag}/tree-sitter-linux-${ts_arch}.gz"
log "downloading $url"
curl -fsSL "$url" | gunzip > /usr/local/bin/tree-sitter
chmod 0755 /usr/local/bin/tree-sitter
log "installed /usr/local/bin/tree-sitter"

user="${_REMOTE_USER:-root}"
home="${_REMOTE_USER_HOME:-$(getent passwd "$user" | cut -d: -f6)}"
[ -n "$home" ] || fail "could not determine home of $user"
group="$(id -gn "$user")"
config="$home/.config/nvim"

if [ -e "$config" ]; then
    log "WARNING: $config already exists, not installing the bundled config"
    cleanup_apt
    exit 0
fi

if [ ! -d "$home/.config" ]; then
    mkdir -p "$home/.config"
    chown "$user:$group" "$home/.config"
fi
cp -r "$(dirname "$0")/config" "$config"
chown -R "$user:$group" "$config"
log "installed LazyVim config to $config"

as_user() {
    if [ "$user" = root ]; then
        HOME="$home" "$@"
    else
        runuser -u "$user" -- env HOME="$home" "$@"
    fi
}

# Install now, so the first start in the container doesn't download and
# compile for minutes: on startup lazy.nvim installs the plugins (at the
# commits in lazy-lock.json), then LazyVim the treesitter parsers. One run,
# since quitting while the parsers install leaves broken leftovers.
log "installing plugins and treesitter parsers"
as_user nvim --headless "+luafile $(dirname "$0")/wait-for-parsers.lua"

cleanup_apt
