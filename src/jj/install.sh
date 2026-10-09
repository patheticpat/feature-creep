#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

ensure_packages curl ca-certificates tar

version="${VERSION:-latest}"
if [ "$version" = "latest" ]; then
    tag="$(github_latest_tag jj-vcs/jj)"
else
    tag="v${version#v}"
fi

install_from_tarball \
    "https://github.com/jj-vcs/jj/releases/download/${tag}/jj-${tag}-$(detect_arch)-unknown-linux-musl.tar.gz" \
    jj

# zsh completion: an autoload stub in the default fpath that loads jj's
# dynamic completion (bookmarks, revisions, ...) on first use, so it always
# matches the installed jj. Works with any compinit (e.g. oh-my-zsh).
install -d /usr/local/share/zsh/site-functions
cat > /usr/local/share/zsh/site-functions/_jj <<'EOF'
#compdef jj
# Installed by feature-creep/jj.
source <(COMPLETE=zsh jj)
_clap_dynamic_completer_jj "$@"
EOF
log "installed zsh completion"

# The host's ~/.config/jj is bind-mounted to a fixed path (feature mounts
# cannot know the remote user's home). Link it to where jj looks for it, so
# both the user config and the per-repo configs (repos/<config-id>/) work.
mount_target=/usr/local/share/jj-host
user="${_REMOTE_USER:-root}"
home="${_REMOTE_USER_HOME:-$(getent passwd "$user" | cut -d: -f6)}"
[ -n "$home" ] || fail "could not determine home of $user"
link="$home/.config/jj"

if [ -e "$link" ] && [ ! -L "$link" ]; then
    log "WARNING: $link already exists, not linking it to $mount_target"
else
    group="$(id -gn "$user")"
    if [ ! -d "$home/.config" ]; then
        mkdir -p "$home/.config"
        chown "$user:$group" "$home/.config"
    fi
    ln -sfn "$mount_target" "$link"
    chown -h "$user:$group" "$link"
    log "linked $link -> $mount_target"
fi

cleanup_apt
