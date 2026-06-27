#!/usr/bin/env bash

setup_gpg() {
  info "GnuPG"
  GPG_CHANGED=0

  if has defaults; then
    write_gpgtools_bool DisableKeychain yes
    write_gpgtools_bool UseKeychain no
  else
    skip "GPGTools defaults"
  fi

  if has pinentry-touchid; then
    setup_pinentry_touchid
  fi

  if [ "$GPG_CHANGED" -eq 1 ] && has gpgconf; then
    step "restart gpg-agent"
    gpgconf --kill gpg-agent || true
  fi
}

setup_pinentry_touchid() {
  local config
  config="$HOME/.gnupg/gpg-agent.conf"

  if [ -f "$config" ] && grep -q 'pinentry-touchid' "$config"; then
    skip "pinentry-touchid"
  else
    step "pinentry-touchid"
    pinentry-touchid -fix
    GPG_CHANGED=1
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
