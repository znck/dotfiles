#!/usr/bin/env bash

set -e

# stringify wraps all arguments in quotes.
function _stringify {
  local input="$@"

  input="${input//\"/\\\"}"
  input="${input//\\/\\\\}"

  echo "\"${input}\""
}


if [ -z "${ALIAS_TARGET}" ]; then
  ALIAS_TARGET="${HOME}/.alias"
fi

# aliasthat creates an alias for last command.
function aliasthat {
	if [ -z "${1}" ]; then
		 echo 'Provide alias name yo!';

     return 1
	fi

  # Find last command.
  local command=$(fc -nlr -1)

  if [ "${command}" = "aliasthat" ]; then
    command=$(fc -nlr -2 -2)
  fi

  if [ ! -f "${ALIAS_TARGET}" ]; then
    echo '#!/usr/bin/env sh' > "${ALIAS_TARGET}"
  fi

  if [ ! -z "$(command -v $1)" ]; then
    echo "Alias already exists.\n  \e[91m$(command -v $1)\e[0m"
    
    return 1
  fi

  if [[ "${command}" =~ '\$[{]?(@|\*|[0-9]+)[}]?' ]]; then
    echo "function __${1}__ { "${command}" }" >> "${ALIAS_TARGET}"
    echo "alias ${1}=$(_stringify __${1}__)" >> "${ALIAS_TARGET}"
    echo "#compdef ${1}=$(echo ${command} | awk '{print $1;}')" >> "${ALIAS_TARGET}"
  else 
    echo "alias ${1}=$(_stringify ${command})" >> "${ALIAS_TARGET}"
    echo "#compdef ${1}=$(echo ${command} | awk '{print $1;}')" >> "${ALIAS_TARGET}"
  fi
  
  . "${ALIAS_TARGET}"

  echo "You may use \e[92m${1}\e[0m instead of \e[94m${command}\e[0m."
}

set +e
