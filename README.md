# feature-creep

Personal [Dev Container Features](https://containers.dev/implementors/features/), meant to be injected into
*any* devcontainer via VS Code's `dev.containers.defaultFeatures`, so the team's devcontainer stays untouched.

| Feature       | Contents                                                                                       |
| ------------- | ---------------------------------------------------------------------------------------------- |
| `personal`    | Meta feature, pulls in all of the below via `dependsOn`                                        |
| `jj`          | jj + bind mount of the host's `~/.config/jj` (user config **and** per-repo configs)            |
| `difftastic`  | `difft`                                                                                        |
| `mergiraf`    | `mergiraf`                                                                                     |
| `shell-tools` | vim (`EDITOR=vim`), fzf, ripgrep, fd, bat, starship, zoxide, eza – each can be toggled off     |

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

## Development

```sh
scripts/sync-lib.sh   # copy lib/common.sh into the features (published features can't share files)
shellcheck src/*/install.sh lib/*.sh scripts/*.sh
npx @devcontainers/cli features test -f jj -f difftastic -f mergiraf -f shell-tools \
    --skip-scenarios -i mcr.microsoft.com/devcontainers/base:debian .
npx @devcontainers/cli features test --global-scenarios-only .   # personal, needs published features
```

## Releasing

Bump `version` in the feature's `devcontainer-feature.json` and push to `main`. The
[workflow](.gitea/workflows/release.yaml) publishes every feature whose version doesn't exist in the registry yet
(tags `1`, `1.x`, `1.x.y`, `latest`).

One-time setup: a Gitea token with `write:package` as **user-level** secret `REGISTRY_TOKEN` (shared with other
repos publishing to the registry); the registry user is the repo owner. Actions must be enabled for the repository.
