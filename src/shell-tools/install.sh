#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

arch="$(detect_arch)"

packages=(curl ca-certificates tar)
[ "${VIM:-true}" = "true" ] && packages+=(vim)
[ "${FZF:-true}" = "true" ] && packages+=(fzf)
[ "${RIPGREP:-true}" = "true" ] && packages+=(ripgrep)
[ "${FD:-true}" = "true" ] && packages+=(fd-find)
[ "${BAT:-true}" = "true" ] && packages+=(bat)
[ "${LESS:-true}" = "true" ] && packages+=(less)
ensure_packages "${packages[@]}"

# Debian/Ubuntu ship these under different names.
if [ "${FD:-true}" = "true" ] && ! command -v fd >/dev/null; then
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi
if [ "${BAT:-true}" = "true" ] && ! command -v bat >/dev/null; then
    ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

if [ "${STARSHIP:-true}" = "true" ]; then
    install_from_tarball \
        "https://github.com/starship/starship/releases/latest/download/starship-${arch}-unknown-linux-musl.tar.gz" \
        starship
fi

if [ "${ZOXIDE:-true}" = "true" ]; then
    tag="$(github_latest_tag ajeetdsouza/zoxide)"
    install_from_tarball \
        "https://github.com/ajeetdsouza/zoxide/releases/download/${tag}/zoxide-${tag#v}-${arch}-unknown-linux-musl.tar.gz" \
        zoxide
fi

if [ "${EZA:-true}" = "true" ]; then
    install_from_tarball \
        "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" \
        eza
fi

cleanup_apt
