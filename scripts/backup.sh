function backup() {
    rsync -aP --delete --exclude 'node_modules' "$HOME/Workspace" "/Volumes/disk0"
}

function restore() {
    echo "Do you wish to restore Workspace from backup?"
    select yn in "Yes" "No"
    case $yn in
        Yes ) rsync -aP --delete  --exclude 'node_modules' "/Volumes/disk0/Workspace" "$HOME"; return ;;
        No ) return ;;
    esac
}
