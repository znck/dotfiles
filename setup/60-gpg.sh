#!/usr/bin/env bash

setup_gpg() {
  info "GnuPG"
  GPG_CHANGED=0

  if has defaults; then
    write_gpgtools_bool DisableKeychain no
    write_gpgtools_bool UseKeychain yes
  else
    skip "GPGTools defaults"
  fi

  if [ "$GPG_CHANGED" -eq 1 ] && has gpgconf; then
    step "restart gpg-agent"
    gpgconf --kill gpg-agent || true
  fi
}


write_gpgtools_bool() {
  local key expected current
  key="$1"
  expected="$2"
  current="$(defaults read org.gpgtools.common "$key" 2>/dev/null || true)"

  case "$expected:$current" in
    yes:1 | no:0)
      skip "org.gpgtools.common $key"
      ;;
    *)
      step "org.gpgtools.common $key"
      defaults write org.gpgtools.common "$key" -bool "$expected"
      GPG_CHANGED=1
      ;;
  esac
}
