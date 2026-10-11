#!/usr/bin/env bash
# oh-my-zsh loads zsh-autosuggestions and zsh-syntax-highlighting before the
# block. fzf-tab must still be the last to bind Tab, with fzf's own Tab
# completion behind it (as on a host that sources fzf before fzf-tab).
set -e
source dev-container-features-test-lib

check "plugins loaded" zsh -ic '(( $+functions[_zsh_autosuggest_start] && $+functions[_zsh_highlight] ))'
check "fzf-tab binds Tab last" bash -c 'zsh -ic "bindkey \"^I\"" | grep -q fzf-tab-complete'
check "fzf completion behind fzf-tab" bash -c 'zsh -ic "zle -la" | grep -qx .fzf-tab-orig-fzf-completion'
check "fzf key bindings" bash -c 'zsh -ic "bindkey \"^R\"" | grep -q fzf-history-widget'

reportResults
