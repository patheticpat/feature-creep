#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

ensure_packages curl ca-certificates tar

version="${VERSION:-latest}"
if [ "$version" = "latest" ]; then
    version="$(github_latest_tag Wilfred/difftastic)"
fi
version="${version#v}"

install_from_tarball \
    "https://github.com/Wilfred/difftastic/releases/download/${version}/difft-${version}-$(detect_arch)-unknown-linux-gnu.tar.gz" \
    difft

cleanup_apt
