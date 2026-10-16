#!/usr/bin/env bash
# Root user, no git or compiler in the base image.
set -e
source dev-container-features-test-lib

check "nvim" nvim --version
check "LazyVim installed" test -d "$HOME/.local/share/nvim/lazy/LazyVim"
check "treesitter parser installed" bash -c 'ls "$HOME"/.local/share/nvim/site/parser/lua.so'
check "starts without messages" bash -c '[ -z "$(nvim --headless "+lua vim.defer_fn(function() vim.cmd.qall() end, 2000)" 2>&1)" ]'

reportResults
