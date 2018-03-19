#!/usr/bin/env sh

set -e

function __print_files__ {
  echo "$1:"
  shift
  echo ${@}
  echo
}

function list_files {
  local DIRS=()
  local OPTS=()

  for elem in "${X[@]}"; do [[ $elem == -* ]] && OPTS+=("$elem") || DIRS+=("$elem"); done

  if [ "${#DIRS[@]}" = 0 ]; then
    DIRS='.'
  fi

  case "$1" in
    today)
      shift
      __print_files__ "Today" "${OPTS}" "$(find . -maxdepth 1 -mtime -1)"
      ;;
    yesterday)
      __print_files__ "Yesterday" "${OPTS}" "$(find . -maxdepth 1 -mtime -2d -mtime +1)"
      shift
      ;;
    week)
      __print_files__ "This Week" "${OPTS}" "$(find . -maxdepth 1 -mtime -7d -mtime +2d)"
      shift
      ;;
    month)
      __print_files__ "This Month" "${OPTS}" "$(find . -maxdepth 1 -mtime -1m -mtime +7d)"
      shift
      ;;
    older)
      __print_files__ "Older" "${OPTS}" "$(find . -maxdepth 1 -mtime +1m)"
      shift
      ;;
    all)
      list_files today "$@"
      list_files yesterday "$@"
      list_files week "$@"
      list_files month "$@"
      list_files older "$@"
      ;;
    *)
      list_files today "$@"
      list_files yesterday "$@"
      list_files week "$@"
      ;;
  esac
}

set +e