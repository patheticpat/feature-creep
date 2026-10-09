#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "jj runs" jj --version
check "config dir linked" bash -c '[ "$(readlink "$HOME/.config/jj")" = /usr/local/share/jj-host ]'
check "zsh completion installed" grep -q '^#compdef jj' /usr/local/share/zsh/site-functions/_jj
check "dynamic completer defined" bash -c 'COMPLETE=zsh jj | grep -q "_clap_dynamic_completer_jj()"'

reportResults
