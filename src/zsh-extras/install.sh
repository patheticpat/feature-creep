#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

fzf_tab="${FZFTAB:-true}"
fzf_keys="${FZFKEYBINDINGS:-true}"
history="${PERSISTHISTORY:-true}"

# Must match the mount target in devcontainer-feature.json.
history_dir=/usr/local/share/zsh-history
fzf_tab_dir=/usr/local/share/fzf-tab
user="${_REMOTE_USER:-root}"
home="${_REMOTE_USER_HOME:-$(getent passwd "$user" | cut -d: -f6)}"
[ -n "$home" ] || fail "could not determine home of $user"
group="$(id -gn "$user")"

packages=(curl ca-certificates tar)
if [ "$fzf_tab" = true ] || [ "$fzf_keys" = true ]; then
    packages+=(fzf)
fi
ensure_packages "${packages[@]}"

if [ "$fzf_tab" = true ]; then
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/Aloxaf/fzf-tab/archive/refs/heads/master.tar.gz | tar -xz -C "$tmp"
    rm -rf "$fzf_tab_dir"
    mv "$tmp"/fzf-tab-* "$fzf_tab_dir"
    rm -rf "$tmp"
    log "installed fzf-tab"
fi

# A fresh named volume takes over the owner of the image directory.
install -d -o "$user" -g "$group" "$history_dir"

# Appended to ~/.zshrc, i.e. after compinit (e.g. oh-my-zsh), which fzf-tab
# needs. zsh reads HISTFILE only after all startup files, so setting it here
# works. Replaced as a whole on reinstall.
block="$(
    echo '# >>> feature-creep zsh-extras >>>'
    if [ "$fzf_tab" = true ]; then
        echo "if [ -r $fzf_tab_dir/fzf-tab.plugin.zsh ]; then"
        echo "    source $fzf_tab_dir/fzf-tab.plugin.zsh"
        echo "    zstyle ':completion:*' menu no"
        echo 'fi'
    fi
    if [ "$fzf_keys" = true ]; then
        echo 'if command -v fzf >/dev/null && fzf --zsh >/dev/null 2>&1; then'
        echo '    source <(fzf --zsh)'
        echo 'elif [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]; then'
        echo '    source /usr/share/doc/fzf/examples/key-bindings.zsh  # fzf < 0.48'
        echo 'fi'
    fi
    if [ "$history" = true ]; then
        echo "if [ -w $history_dir ]; then"
        echo "    HISTFILE=$history_dir/.zsh_history"
        echo '    HISTSIZE=100000'
        echo '    SAVEHIST=100000'
        echo '    setopt INC_APPEND_HISTORY'
        echo 'fi'
    fi
    echo '# <<< feature-creep zsh-extras <<<'
)"

zshrc="$home/.zshrc"
if [ -f "$zshrc" ]; then
    sed -i '/^# >>> feature-creep zsh-extras >>>$/,/^# <<< feature-creep zsh-extras <<<$/d' "$zshrc"
else
    install -o "$user" -g "$group" -m 0644 /dev/null "$zshrc"
fi
printf '\n%s\n' "$block" >> "$zshrc"
log "updated $zshrc"

# Entrypoints don't know the remote user: bake it in.
install -d /usr/local/share/feature-creep
sed "s|@REMOTE_USER@|$user|" "$(dirname "$0")/zsh-extras-init.sh" \
    > /usr/local/share/feature-creep/zsh-extras-init.sh
chmod 0755 /usr/local/share/feature-creep/zsh-extras-init.sh

cleanup_apt
