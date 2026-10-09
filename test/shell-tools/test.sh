#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "vim" vim --version
check "EDITOR" bash -c '[ "$EDITOR" = vim ]'
check "less" less --version
check "man" man -w ls
check "fzf" fzf --version
check "rg" rg --version
check "fd" fd --version
check "bat" bat --version
check "starship" starship --version
check "zoxide" zoxide --version
check "eza" eza --version

reportResults
