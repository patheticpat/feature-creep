# feature-creep

Personal [Dev Container Features](https://containers.dev/implementors/features/), meant to be injected into
*any* devcontainer via VS Code's `dev.containers.defaultFeatures`, so the team's devcontainer stays untouched.

| Feature         | Contents                                                                                         |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `personal`      | Meta feature, pulls in all of the below via `dependsOn` (except `venv-extras`)                   |
| `jj`            | jj + zsh completion + bind mount of the host's `~/.config/jj`; VS Code: jj-view, built-in git off |
| `difftastic`    | `difft`                                                                                          |
| `mergiraf`      | `mergiraf`                                                                                       |
| `shell-tools`   | vim (`EDITOR=vim`), less, fzf, ripgrep, fd, bat, starship, zoxide, eza – each can be toggled off |
| `timezone`      | Container time zone = host time zone (read-only mount of the host's `/etc/localtime`)            |
| `zsh-extras`    | fzf-tab, fzf keys, history + zoxide volume per devcontainer, eza aliases, zoxide, starship – in `~/.zshrc` |
| `docker-socket` | Remote user joins the group owning a mounted `/var/run/docker.sock` (GID differs per host)       |
| `claude-config` | Claude Code config (`CLAUDE_CONFIG_DIR`, `~/.claude`) in the named volume `claude-code-config`   |
| `venv-extras`   | Extra Python packages for matching venvs via a `sitecustomize` overlay – per project, see below  |

Published to `git.adminforge.de/patheticpat/feature-creep/<feature>`. Debian/Ubuntu images only.

## Usage

1. Log in to the registry on the host (Gitea token with `read:package`):
   ```sh
   docker login git.adminforge.de
   ```
2. In VS Code **user** settings (`settings.json`):
   ```json
   "dev.containers.defaultFeatures": {
     "git.adminforge.de/patheticpat/feature-creep/personal:1": {}
   }
   ```
3. Rebuild the container.

Instead of `personal`, single features can be listed to pass options, e.g.
`"git.adminforge.de/patheticpat/feature-creep/shell-tools:1": { "eza": false }`.

### jj config

The `jj` feature bind-mounts the host's `~/.config/jj` (read-write) to `/usr/local/share/jj-host` and links
`~/.config/jj` of the container user to it. Per-repo configs work because jj looks them up via
`.jj/repo/config-id`, which comes along with the workspace mount. Since the repo path differs inside the
container, jj treats the repo as *moved* and silently updates the stored path in
`repos/<id>/metadata.binpb`. That happens again in the other direction on the host and is harmless.

### Time zone

The `timezone` feature mounts the host's `/etc/localtime` read-only to `/usr/local/share/host-localtime`. On
every container start its entrypoint looks for the zone in `/usr/share/zoneinfo` with identical content and
points `/etc/localtime` and `/etc/timezone` at it, so tools that need a zone *name* (ICU: Node, Java) get e.g.
`Europe/Berlin` instead of UTC. If host and container tzdata differ so that nothing matches, the host file is
copied to `/etc/localtime`: local time is still right, only the name is unknown.

### Entrypoints

`timezone`, `docker-socket`, `claude-config` and `zsh-extras` fix things up on every container start. Entrypoints run
as the container user; if that isn't root they use passwordless `sudo`, otherwise they log and skip.

### Volumes

Named volumes of features get the compose project prefix in compose-based devcontainers (e.g.
`mytalkmaster_devcontainer_claude-code-config`), so `claude-config` is shared per compose project, but across all
image-based devcontainers. `zsh-extras` uses one volume per devcontainer (`zsh-history-${devcontainerId}`).

### venv-extras

Project-specific (package list, venv location), so it goes into the project's `devcontainer.json` instead of
`defaultFeatures`:

```json
"features": {
    "git.adminforge.de/patheticpat/feature-creep/venv-extras:1": {
        "packages": "pytest pytest-django ipython",
        "venvs": "/workspace/.venv/*"
    }
}
```

The packages are installed at build time into `/usr/local/share/venv-extras/site` for the base interpreter. A
`sitecustomize.py` in its stdlib dir appends that directory to `sys.path` of every venv whose `sys.prefix` matches
`venvs`, so venvs that get recreated (e.g. `UV_VENV_CLEAR=1`) see them immediately, and the venv's own packages
always win. Console scripts get wrappers in `/usr/local/bin` that run with the active venv's `python`. Only works
for venvs created from the image's interpreter; packages update on rebuild.

## Development

```sh
scripts/sync-lib.sh   # copy lib/common.sh into the features (published features can't share files)
shellcheck src/*/install.sh lib/*.sh scripts/*.sh
npx @devcontainers/cli features test -f jj -f difftastic -f mergiraf -f shell-tools -f timezone \
    -f zsh-extras -f docker-socket -f claude-config -f venv-extras --skip-scenarios -i mcr.microsoft.com/devcontainers/base:debian .
npx @devcontainers/cli features test -f docker-socket -f venv-extras -f zsh-extras --skip-autogenerated .  # scenarios
npx @devcontainers/cli features test --global-scenarios-only .   # personal, needs published features
```

## Releasing

Bump `version` in the feature's `devcontainer-feature.json` and push to `main`. The
[workflow](.gitea/workflows/release.yaml) publishes every feature whose version doesn't exist in the registry yet
(tags `1`, `1.x`, `1.x.y`, `latest`).

One-time setup: a Gitea token with `write:package` as **user-level** secret `REGISTRY_TOKEN` (shared with other
repos publishing to the registry); the registry user is the repo owner. Actions must be enabled for the repository.
