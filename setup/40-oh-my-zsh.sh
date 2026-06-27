#!/usr/bin/env bash

setup_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    info "oh-my-zsh"
    skip "$HOME/.oh-my-zsh"
    return
  fi

  info "Installing oh-my-zsh"
  export KEEP_ZSHRC="yes"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}
