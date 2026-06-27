#!/usr/bin/env bash

info() {
  echo ""
  echo "# $*"
}

step() {
  echo "- $*"
}

skip() {
  echo "- $* (skip)"
}

has() {
  command -v "$1" >/dev/null 2>&1
}
