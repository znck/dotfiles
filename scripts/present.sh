function __highlight {
  if [ -z "$2" ]
    then src="pbpaste"
  else
    src="cat $2"
  fi
  $src | highlight -O rtf --syntax $1 --font 'Fira Code' --style solarized-light --font-size 28 | pbcopy
}

alias highlight-it=__highlight