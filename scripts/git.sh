function _confirm() {
  while true
  do
    choice=$(bash -c 'read -r -p "Continue? (y/n) " choice; echo $choice')
    case "$choice" in
      y|Y|yes|YES|Yes ) return 0
        ;;
      n|N|no|NO|No ) return 1
        ;;
      * ) echo "invalid"
        ;;
     esac
  done  
}

function clean_stale_branches() {
  echo git fetch -ap $*
  git fetch -ap $*

  GONE=$(git branch --format '%(refname:short) %(upstream:track)' | grep -vE '(master|develop|dev)' | grep gone | grep --color=never -oE '.* ' | tr -d '\n')
  NOT_TRACKING=($(git branch --format '%(refname:short) %(upstream:short) %(upstream:track)' | grep -vE '(master|develop|dev)' | grep -vE '[^ ]+ [^ \[]+' | grep -vE '\[.*]' | tr -d '\n'))

  if [[ -n "${GONE/[ ]*\n/}" ]] ; then
    echo "Stale branches:"
    echo "$(echo ${GONE} | tr ' ' '\n')" | sed 's/^/ - /'
    _confirm && git branch -D ${GONE}
    echo
  fi

  if [ ${#NOT_TRACKING[@]} -gt 0 ]; then
    echo "Untracked branches:"
    for BRANCH in ${NOT_TRACKING}
    do
      echo "Delete: ${BRANCH}"
      _confirm && git branch -D ${BRANCH}
      echo
    done
  fi
}
