#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "CLAUDE_CONFIG_DIR" bash -c '[ "$CLAUDE_CONFIG_DIR" = /usr/local/share/claude-config ]'
check "volume writable by user" bash -c 'touch "$CLAUDE_CONFIG_DIR/.probe" && rm "$CLAUDE_CONFIG_DIR/.probe"'
check "~/.claude linked" bash -c '[ "$(readlink "$HOME/.claude")" = /usr/local/share/claude-config ]'
check "entrypoint succeeds" /usr/local/share/feature-creep/claude-config-init.sh

reportResults
