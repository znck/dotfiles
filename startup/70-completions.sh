#!/usr/bin/env zsh

[ -s "$HOME/.oh-my-zsh/completions/_bun" ] && source "$HOME/.oh-my-zsh/completions/_bun"
[ -s "${DOTFILES:-$HOME/.dotfiles}/completions/_secrets" ] && source "${DOTFILES:-$HOME/.dotfiles}/completions/_secrets"
