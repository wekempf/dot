#!/bin/sh

set -eu

REPO="${CHEZMOI_REPO:-wekempf/dot}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

log() {
    printf 'dot: %s\n' "$*"
}

fail() {
    printf 'dot: %s\n' "$*" >&2
    exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl is required"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

if ! command -v chezmoi >/dev/null 2>&1; then
    log "installing chezmoi in $BIN_DIR"
    curl -fsLS https://get.chezmoi.io | sh -s -- -b "$BIN_DIR"
else
    log "chezmoi is already installed"
fi

if ! command -v mise >/dev/null 2>&1; then
    log "installing mise in $BIN_DIR"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$BIN_DIR/mise" sh
else
    log "mise is already installed"
fi

log "initializing chezmoi from $REPO"
chezmoi init --apply "$REPO"

log "installing globally configured mise tools"
mise -C "$HOME" install --yes

if [ "${DOT_CHANGE_SHELL:-1}" = "0" ]; then
    log "login shell change disabled by DOT_CHANGE_SHELL=0"
elif command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    current_shell="${SHELL:-}"
    if command -v getent >/dev/null 2>&1; then
        account_shell="$(getent passwd "$(id -un)" | awk -F: '{print $7}')"
        if [ -n "$account_shell" ]; then
            current_shell="$account_shell"
        fi
    fi

    if [ "$current_shell" = "$zsh_path" ]; then
        log "login shell is already $zsh_path"
    elif ! command -v chsh >/dev/null 2>&1; then
        log "zsh is available at $zsh_path, but chsh is unavailable"
    elif [ -r /etc/shells ] && ! grep -Fxq "$zsh_path" /etc/shells; then
        log "zsh is available at $zsh_path, but it is not listed in /etc/shells"
    else
        log "changing login shell to $zsh_path"
        if [ -r /dev/tty ]; then
            if ! chsh -s "$zsh_path" </dev/tty; then
                log "could not change the login shell; run: chsh -s $zsh_path"
            fi
        else
            log "no terminal is available; run: chsh -s $zsh_path"
        fi
    fi
else
    log "zsh is not installed; leaving the login shell unchanged"
fi

log "setup complete; start a new login shell to use the configuration"
