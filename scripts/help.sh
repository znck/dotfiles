#!/usr/bin/env sh

# stringify wraps all arguments in quotes.
function stringify {
  local input="$@"
  
  input="${input//\"/\\\"}"
  input="${input//\\/\\\\}"
  input="${input// /+}"

  echo "${input}"
}

# Find help on cheat.sh
function help {
  curl "cheat.sh/$(stringify $@)"
}
