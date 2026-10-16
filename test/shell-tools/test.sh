#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

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
