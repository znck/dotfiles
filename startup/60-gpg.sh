#!/usr/bin/env zsh

if gpg_tty="$(tty 2>/dev/null)" && [[ "$gpg_tty" != "not a tty" ]]; then
  export GPG_TTY="$gpg_tty"
else
  unset GPG_TTY
fi
unset gpg_tty
