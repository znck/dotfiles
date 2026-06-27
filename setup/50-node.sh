#!/usr/bin/env bash

setup_node() {
  info "Node"
  export N_PREFIX="$HOME/.n"

  if has node; then
    skip "node $(node --version)"
  else
    step "node"
    n latest
  fi

  if has pnpm; then
    skip "pnpm $(pnpm --version)"
  elif has corepack; then
    step "corepack"
    corepack enable
  fi
}
