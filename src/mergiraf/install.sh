#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

ensure_packages curl ca-certificates tar

version="${VERSION:-latest}"
if [ "$version" = "latest" ]; then
    tag="$(codeberg_latest_tag mergiraf/mergiraf)"
    [ -n "$tag" ] || fail "could not resolve latest mergiraf release"
else
    tag="v${version#v}"
fi

install_from_tarball \
    "https://codeberg.org/mergiraf/mergiraf/releases/download/${tag}/mergiraf_$(detect_arch)-unknown-linux-musl.tar.gz" \
    mergiraf

cleanup_apt
