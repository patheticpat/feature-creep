#!/usr/bin/env bash
# Copies lib/common.sh into every feature that sources it.
# Published features are self-contained tarballs, so they cannot share files.
set -euo pipefail
cd "$(dirname "$0")/.."

for feature in src/*/; do
    if grep -q 'common\.sh' "$feature/install.sh"; then
        cp lib/common.sh "$feature/common.sh"
    fi
done
