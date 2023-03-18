function backup() {
    rsync -aP --delete --exclude 'node_modules' "$HOME/Workspace" "/Volumes/disk0"
}

function restore() {
    echo "Do you wish to restore Workspace from backup?"
    while true; do
      read -p "$* [y/n]: " yn
      case $yn in
          [Yy]*) rsync -aP --delete  --exclude 'node_modules' "/Volumes/disk0/Workspace" "$HOME"; return ;;
          [Nn]*) return  ;;
      esac
    done    
}
