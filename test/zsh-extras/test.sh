#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "fzf-tab installed" test -r /usr/local/share/fzf-tab/fzf-tab.plugin.zsh
check "block in .zshrc" grep -q '^# >>> feature-creep zsh-extras >>>$' "$HOME/.zshrc"
check "block only once" bash -c '[ "$(grep -c "^# >>> feature-creep zsh-extras" "$HOME/.zshrc")" = 1 ]'
check "history volume writable" bash -c 'touch /usr/local/share/zsh-history/.probe && rm /usr/local/share/zsh-history/.probe'
check "HISTFILE in volume" zsh -ic '[ "$HISTFILE" = /usr/local/share/zsh-history/.zsh_history ]'
check "fzf-tab loaded" zsh -ic 'whence -w fzf-tab-complete >/dev/null'
check "fzf key bindings" zsh -ic 'bindkey "^R" | grep -q fzf-history-widget'
check "entrypoint succeeds" /usr/local/share/feature-creep/zsh-extras-init.sh

reportResults
