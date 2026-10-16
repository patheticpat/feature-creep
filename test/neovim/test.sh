#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "nvim" nvim --version
check "nvim >= 0.11.2" nvim --headless "+lua if vim.fn.has('nvim-0.11.2') == 0 then vim.cmd.cquit() end" +qa
check "EDITOR" bash -c '[ "$EDITOR" = nvim ]'
check "tree-sitter" tree-sitter --version
check "config installed" test -f "$HOME/.config/nvim/lua/config/lazy.lua"
check "config owned by user" bash -c '[ "$(stat -c %U "$HOME/.config/nvim")" = "$(id -un)" ]'
check "LazyVim installed" test -d "$HOME/.local/share/nvim/lazy/LazyVim"
check "plugins at locked commits" bash -c '
    commit="$(grep -o "\"LazyVim\": {[^}]*" "$HOME/.config/nvim/lazy-lock.json" | grep -o "[0-9a-f]\{40\}")"
    [ "$(git -C "$HOME/.local/share/nvim/lazy/LazyVim" rev-parse HEAD)" = "$commit" ]'
check "treesitter parser installed" bash -c 'ls "$HOME"/.local/share/nvim/site/parser/lua.so'
check "starts without messages" bash -c '[ -z "$(nvim --headless "+lua vim.defer_fn(function() vim.cmd.qall() end, 2000)" 2>&1)" ]'

reportResults
