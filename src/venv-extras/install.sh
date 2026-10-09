#!/usr/bin/env bash
# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

packages="${PACKAGES:-}"
venvs="${VENVS:-/workspace/.venv/*}"
interpreter="${INTERPRETER:-python3}"

overlay=/usr/local/share/venv-extras
site_dir="$overlay/site"
marker="# Installed by feature-creep/venv-extras."

if [ -z "${packages// /}" ]; then
    log "no packages given, nothing to do"
    exit 0
fi

python="$(command -v "$interpreter" || true)"
if [ -z "$python" ]; then
    log "WARNING: $interpreter not found, not installing venv extras"
    exit 0
fi
python="$(readlink -f "$python")"
log "base interpreter: $python ($("$python" --version 2>&1))"

ensure_packages curl ca-certificates tar

# A throwaway uv: the image's own uv (if any) may not be on root's PATH.
tmp="$(mktemp -d)"
curl -fsSL "https://github.com/astral-sh/uv/releases/latest/download/uv-$(detect_arch)-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$tmp" --strip-components=1
rm -rf "$site_dir"
# shellcheck disable=SC2086 # word splitting of the package list is intended
"$tmp/uv" pip install --no-cache --python "$python" --target "$site_dir" $packages
rm -rf "$tmp"
chmod -R a+rX "$overlay"

# sitecustomize in the base interpreter's stdlib dir: venvs created from it
# have that dir on sys.path, so it runs at startup of every such venv, even
# one recreated from scratch.
stdlib="$("$python" -c 'import sysconfig; print(sysconfig.get_paths()["stdlib"])')"
target="$stdlib/sitecustomize.py"
orig="$stdlib/_venv_extras_orig_sitecustomize.py"
if [ -f "$target" ] && ! grep -qF "$marker" "$target"; then
    mv "$target" "$orig"
    log "existing sitecustomize kept as $orig"
fi
other="$("$python" -c 'import importlib.util as u; s = u.find_spec("sitecustomize"); print(s.origin if s else "")' 2>/dev/null || true)"
if [ -n "$other" ] && [ "$other" != "$target" ]; then
    log "WARNING: $other will be shadowed by $target"
fi
"$python" - "$target" "$site_dir" "$venvs" "$marker" <<'PY'
import sys

target, site_dir, venvs, marker = sys.argv[1:]
with open(target, "w") as f:
    f.write(f'''{marker}
# Appends the overlay with extra packages to sys.path of matching venvs; the
# venv's own packages always take precedence.
import fnmatch
import site
import sys

_OVERLAY = {site_dir!r}
_VENVS = {venvs.split()!r}

if sys.prefix != sys.base_prefix and any(fnmatch.fnmatch(sys.prefix, p) for p in _VENVS):
    site.addsitedir(_OVERLAY)

try:
    import _venv_extras_orig_sitecustomize  # noqa: F401
except ImportError:
    pass
''')
PY
log "installed $target for venvs matching: $venvs"

# Console scripts: run them with whatever python is first on PATH, i.e. the
# active venv. Native binaries are linked as they are.
for script in "$site_dir"/bin/*; do
    [ -f "$script" ] || continue
    name="$(basename "$script")"
    dest="/usr/local/bin/$name"
    if [ -e "$dest" ] && ! grep -qF "$marker" "$dest" 2>/dev/null && [ "$(readlink "$dest")" != "$script" ]; then
        log "WARNING: $dest exists, not shadowing it"
        continue
    fi
    if head -n 1 "$script" | grep -q '^#!.*python'; then
        cat > "$dest" <<SH
#!/bin/sh
$marker
if [ -z "\${VIRTUAL_ENV:-}" ]; then
    echo "$name: activate a venv first (extras are only visible inside venvs)" >&2
    exit 1
fi
exec python "$script" "\$@"
SH
        chmod 0755 "$dest"
    else
        ln -sfn "$script" "$dest"
    fi
    log "added $dest"
done

cleanup_apt
