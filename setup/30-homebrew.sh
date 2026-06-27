#!/usr/bin/env bash

setup_homebrew() {
  if ! has brew; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    export PATH="/opt/homebrew/bin:$PATH"
  else
    info "Homebrew"
    skip "brew"
  fi

  brew analytics off >/dev/null
  export HOMEBREW_NO_AUTO_UPDATE=1

  setup_brew_taps
  setup_brew_trust
  setup_brew_packages
}

setup_brew_taps() {
  local tap

  info "Homebrew taps"
  for tap in "${BREW_TAPS[@]}"; do
    if brew tap | grep -qx "$tap"; then
      skip "$tap"
      continue
    fi

    step "$tap"
    brew tap "$tap"
  done
}

setup_brew_trust() {
  local tap

  info "Homebrew trust"
  for tap in "${BREW_TAPS[@]}"; do
    if brew trust --json v1 2>/dev/null | grep -q "\"$tap\""; then
      skip "$tap"
      continue
    fi

    step "$tap"
    brew trust --tap "$tap"
  done
}

setup_brew_packages() {
  local package

  info "Homebrew packages"
  for package in "${BREW_PACKAGES[@]}"; do
    if brew list "$package" >/dev/null 2>&1; then
      skip "$package"
      continue
    fi

    step "$package"
    brew install "$package"
  done
}
