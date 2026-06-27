#!/usr/bin/env bash

if [ -z "${ALIAS_TARGET:-}" ]; then
  ALIAS_TARGET="${HOME}/.alias"
fi

_aliasthat_stringify() {
  local input="$*"

  input="${input//\"/\\\"}"
  input="${input//\\/\\\\}"

  echo "\"${input}\""
}

aliasthat() {
  if [ -z "${1:-}" ]; then
    echo 'Provide alias name yo!'
    return 1
  fi

  local command
  command="$(fc -nlr -1)"

  if [ "$command" = "aliasthat" ]; then
    command="$(fc -nlr -2 -2)"
  fi

  if [ ! -f "$ALIAS_TARGET" ]; then
    echo '#!/usr/bin/env sh' >"$ALIAS_TARGET"
  fi

  if command -v "$1" >/dev/null 2>&1; then
    printf 'Alias already exists.\n  \033[91m%s\033[0m\n' "$(command -v "$1")"
    return 1
  fi

  if [[ "$command" =~ \$[\{]?(@|\*|[0-9]+)[\}]? ]]; then
    echo "function __${1}__ { ${command}; }" >>"$ALIAS_TARGET"
    echo "alias ${1}=$(_aliasthat_stringify "__${1}__")" >>"$ALIAS_TARGET"
  else
    echo "alias ${1}=$(_aliasthat_stringify "$command")" >>"$ALIAS_TARGET"
  fi

  echo "#compdef ${1}=$(echo "$command" | awk '{print $1;}')" >>"$ALIAS_TARGET"

  . "$ALIAS_TARGET"

  printf 'You may use \033[92m%s\033[0m instead of \033[94m%s\033[0m.\n' "$1" "$command"
}
