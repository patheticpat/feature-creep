#!/usr/bin/env bash
# Resolves the dependsOn features from the registry, so they must be published.
set -e
source dev-container-features-test-lib

check "jj" jj --version
check "difft" difft --version
check "mergiraf" mergiraf --version
check "starship" starship --version
check "nvim" nvim --version
check "LazyVim" test -d "$HOME/.local/share/nvim/lazy/LazyVim"
check "zsh-extras block" grep -q "feature-creep zsh-extras" "$HOME/.zshrc"
check "CLAUDE_CONFIG_DIR" bash -c '[ -n "$CLAUDE_CONFIG_DIR" ]'
check "docker-socket entrypoint" test -x /usr/local/share/feature-creep/docker-socket-init.sh
check "localtime matches host" cmp -s /etc/localtime /usr/local/share/host-localtime

reportResults
