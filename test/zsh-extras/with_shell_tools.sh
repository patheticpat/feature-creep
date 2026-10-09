#!/usr/bin/env bash
# With eza, zoxide and starship from shell-tools, the block wires them up.
set -e
source dev-container-features-test-lib

check "ls is eza" bash -c 'zsh -ic "alias ls" | grep -q eza'
check "ll is eza" bash -c 'zsh -ic "alias ll" | grep -q "eza -l"'
check "zoxide initialized" zsh -ic 'whence -w z >/dev/null'
check "starship prompt" zsh -ic '[[ "$PROMPT" == *starship* ]]'
check "default starship config" zsh -ic '[ "$STARSHIP_CONFIG" = /usr/local/share/feature-creep/starship.toml ]'
check "no container label" bash -c '! zsh -ic "starship prompt" | grep -q Docker'
check "eza lists" zsh -ic 'ls / >/dev/null'

reportResults
