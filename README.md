# dot

Portable dotfiles managed with [chezmoi](https://www.chezmoi.io/) and
[mise](https://mise.jdx.dev/).

## Bootstrap

On a machine with `curl`, run:

```sh
curl -fsSL https://raw.githubusercontent.com/wekempf/dot/main/setup.sh | sh
```

The bootstrapper installs `chezmoi` and `mise` into
`${XDG_BIN_HOME:-$HOME/.local/bin}` when they are missing, applies this
repository with chezmoi, installs the globally configured mise tools, and
changes the login shell to zsh when zsh and `chsh` are available. It does not
require root or `sudo`.

The login-shell change can require your account password. If the operating
system does not permit the change, the bootstrapper prints the command to run
manually and otherwise completes normally. Set `DOT_CHANGE_SHELL=0` to skip
the login-shell change intentionally.

## Daily use

Preview and apply changes from the source state:

```sh
chezmoi diff
chezmoi apply
```

Pull repository changes and apply them:

```sh
chezmoi update
```

Edit a managed file through chezmoi:

```sh
chezmoi edit ~/.config/zsh/.zshrc
chezmoi apply
```

## Current migration scope

The initial migration manages `~/.zshenv`, `~/.config/zsh`, and the global
mise configuration. Just and Node.js are installed through mise when they are
not already available from the host or container. Machine-local
`~/.config/zsh/local_env.zsh`, shell history, completion dumps, and other
runtime state are intentionally unmanaged.
