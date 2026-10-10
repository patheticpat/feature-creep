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

# zsh completion: autoload functions in the default fpath that ask jj itself
# for completions (bookmarks, revisions, ...), so they always match the
# installed jj. Works with any compinit (e.g. oh-my-zsh). Unlike jj's own
# completer, aliases get a description: the text from an [aliases-help]
# table in the jj config (user or repo config), or else the alias expansion.
#   [aliases-help]
#   work = "Move the private change (and @) onto <revset>"
install -d /usr/local/share/zsh/site-functions
cat > /usr/local/share/zsh/site-functions/_jj_alias_descriptions <<'EOF'
#autoload
# Installed by feature-creep/jj.
# Prints "name:description" for every jj alias of the current repo.
emulate -L zsh
setopt extendedglob
local line value
local -A help
for line in ${(f)"$(jj config list aliases-help 2>/dev/null)"}; do
  [[ $line == (#b)aliases-help.([^ ]##)\ =\ (*) ]] && help[$match[1]]=${(Q)match[2]}
done
for line in ${(f)"$(jj config list --include-defaults aliases 2>/dev/null)"}; do
  [[ $line == (#b)aliases.([^ ]##)\ =\ \[(*)\] ]] || continue
  if [[ -n $help[$match[1]] ]]; then
    print -r -- "${match[1]}:${help[$match[1]]}"
  else
    # TOML string array -> shell words: ["rebase", "-s", "x"] -> rebase -s x
    value=${match[2]//\", \"/\" \"}
    print -r -- "${match[1]}:alias for: ${(j: :)${(Q)${(z)value}}}"
  fi
done
EOF
cat > /usr/local/share/zsh/site-functions/_jj <<'EOF'
#compdef jj
# Installed by feature-creep/jj. jj's dynamic completion (COMPLETE=zsh jj),
# plus descriptions for aliases at the subcommand position.
local _CLAP_COMPLETE_INDEX=$(( CURRENT - 1 ))
local -a completions=("${(@f)$(
  _CLAP_IFS=$'\n' _CLAP_COMPLETE_INDEX=$_CLAP_COMPLETE_INDEX COMPLETE=zsh \
    jj -- "${words[@]}" 2>/dev/null
)}")
[[ -n $completions ]] || return 1

if (( CURRENT == 2 )); then
  local -A described
  local entry i
  for entry in "${(@f)$(_jj_alias_descriptions)}"; do
    [[ -n $entry ]] && described[${entry%%:*}]=$entry
  done
  for (( i = 1; i <= $#completions; i++ )); do
    [[ $completions[i] != *:* && -n $described[$completions[i]] ]] && completions[i]=$described[$completions[i]]
  done
fi

# the rest follows jj's own completer: directories get a trailing slash
local -a dirs=() other=()
local completion value
for completion in $completions; do
  value="${completion%%:*}"
  if [[ "$value" == */ ]]; then
    if [[ "$completion" == *:* ]]; then
      dirs+=("${value%/}:${completion#*:}")
    else
      dirs+=("${value%/}")
    fi
  else
    other+=("$completion")
  fi
done
[[ -n $dirs ]] && _describe -V 'values' dirs -S '/' -r '/'
[[ -n $other ]] && _describe -V 'values' other
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
