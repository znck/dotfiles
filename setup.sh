#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

source "$ROOT/setup/00-lib.sh"
source "$ROOT/setup/10-packages.sh"
source "$ROOT/setup/20-config.sh"
source "$ROOT/setup/30-homebrew.sh"
source "$ROOT/setup/40-oh-my-zsh.sh"
source "$ROOT/setup/50-node.sh"
source "$ROOT/setup/60-gpg.sh"

export PATH="$ROOT/bin:/opt/homebrew/bin:$HOME/.n/bin:$PATH"

info "My dotfiles"
link_config
setup_homebrew
setup_oh_my_zsh
setup_node
setup_gpg
info "Done. Start a new terminal session."
