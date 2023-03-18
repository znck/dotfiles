function ask {
  while true; do
      read -p "$* [y/n]: " yn
      case $yn in
          [Yy]*) return 0  ;;  
          [Nn]*) return 1  ;;
      esac
  done
}

function indent() { sed -En 's/^/  /'; }

function isBinary() {
    local _bin="$1" _full_path

    _full_path=$(command -v "${_bin}")
    _status=$?

    if [ ${_status} -eq 0 ]; then
        if [[ -x "${_full_path}" ]]; then
            return 0
        fi
    fi

    return 1
}

# Prints out the relative path between to absolute paths. Trivial.
#
# Parameters:
# $1 = first path
# $2 = second path
#
# Output: the relative path between 1st and 2nd paths
function relative() {
    local pos="${1%%/}" ref="${2%%/}" down=''

    while :; do
        test "$pos" = '/' && break
        case "$ref" in $pos/*) break;; esac
        down="../$down"
        pos=${pos%/*}
    done

    echo "$down${ref##$pos/}"
}
