#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "jj runs" jj --version
check "config dir linked" bash -c '[ "$(readlink "$HOME/.config/jj")" = /usr/local/share/jj-host ]'
check "zsh completion installed" grep -q '^#compdef jj' /usr/local/share/zsh/site-functions/_jj
check "dynamic completion works" bash -c 'COMPLETE=zsh _CLAP_COMPLETE_INDEX=1 jj -- jj "" | grep -q "^log:"'

# alias descriptions: from [aliases-help], else the expansion
cat > /tmp/jj-alias-test.toml <<'EOF'
[aliases]
work = ["rebase", "-s", "private", "-d"]
stack = ["squash", "-A", "exactly(work-tip, 1)", "-B", "private"]

[aliases-help]
work = "Move the private change onto <revset>"
EOF
alias_descriptions() {
    JJ_CONFIG=/tmp/jj-alias-test.toml zsh -fc 'fpath=(/usr/local/share/zsh/site-functions $fpath); autoload -Uz _jj_alias_descriptions; _jj_alias_descriptions'
}
check "alias description from aliases-help" bash -c "$(declare -f alias_descriptions); alias_descriptions | grep -qx 'work:Move the private change onto <revset>'"
check "alias description falls back to expansion" bash -c "$(declare -f alias_descriptions); alias_descriptions | grep -qxF 'stack:alias for: squash -A exactly(work-tip, 1) -B private'"
check "zsh completion parses" zsh -fc 'fpath=(/usr/local/share/zsh/site-functions $fpath); autoload -Uz +X _jj'

reportResults
