#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

arch="$(detect_arch)"

packages=(curl ca-certificates tar)
[ "${FZF:-true}" = "true" ] && packages+=(fzf)
[ "${RIPGREP:-true}" = "true" ] && packages+=(ripgrep)
[ "${FD:-true}" = "true" ] && packages+=(fd-find)
[ "${BAT:-true}" = "true" ] && packages+=(bat)
[ "${LESS:-true}" = "true" ] && packages+=(less)

# Slim images (e.g. python:*-slim) tell dpkg to drop all man pages. Lift that
# before installing, so everything installed from now on keeps its pages.
man_restored=false
if [ "${MAN:-true}" = "true" ]; then
    packages+=(man-db manpages)
    for cfg in /etc/dpkg/dpkg.cfg.d/*; do
        [ -f "$cfg" ] || continue
        if grep -qE '^path-exclude[= ]/usr/share/man/' "$cfg"; then
            sed -i -E 's|^path-exclude[= ]/usr/share/man/|#&|' "$cfg"
            man_restored=true
            log "re-enabled man pages in $cfg"
        fi
    done
fi

ensure_packages "${packages[@]}"

# Packages installed before that have no pages: reinstall the ones whose pages
# are commonly read. All packages would take minutes, these take seconds.
if [ "$man_restored" = true ]; then
    reinstall=()
    for pkg in coreutils bash grep sed findutils tar gzip procps util-linux \
        openssh-client git-man less curl diffutils; do
        dpkg -s "$pkg" >/dev/null 2>&1 && reinstall+=("$pkg")
    done
    if [ "${#reinstall[@]}" -gt 0 ]; then
        if [ -z "$(find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -name '*_Packages' 2>/dev/null | head -1)" ]; then
            apt-get update -y
        fi
        log "reinstalling for their man pages: ${reinstall[*]}"
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --reinstall "${reinstall[@]}"
    fi
fi

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
