#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

# Must match the mount target and CLAUDE_CONFIG_DIR in devcontainer-feature.json.
config_dir=/usr/local/share/claude-config
user="${_REMOTE_USER:-root}"
home="${_REMOTE_USER_HOME:-$(getent passwd "$user" | cut -d: -f6)}"
[ -n "$home" ] || fail "could not determine home of $user"
group="$(id -gn "$user")"

# A fresh named volume takes over owner and contents of the image directory.
install -d -o "$user" -g "$group" "$config_dir"

# Link ~/.claude to the volume too: tools that ignore CLAUDE_CONFIG_DIR, and
# absolute paths stored in the config (e.g. plugin install paths), keep working.
link="$home/.claude"
if [ -d "$link" ] && [ ! -L "$link" ]; then
    log "moving existing $link into $config_dir"
    cp -a "$link/." "$config_dir/"
    rm -rf "$link"
fi
ln -sfn "$config_dir" "$link"
chown -h "$user:$group" "$link"
log "linked $link -> $config_dir"

# Entrypoints don't know the remote user: bake it in.
install -d /usr/local/share/feature-creep
sed "s|@REMOTE_USER@|$user|" "$(dirname "$0")/claude-config-init.sh" \
    > /usr/local/share/feature-creep/claude-config-init.sh
chmod 0755 /usr/local/share/feature-creep/claude-config-init.sh
