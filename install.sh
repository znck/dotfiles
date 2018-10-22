#!/usr/bin/env sh

set -e

indent() { sed 's/^/  /'; }

echo "# My dotfiles"
cd "$(dirname ${0})"
DIR="$(pwd)" # Get script directory.
cd -

echo ""

# Install brew
command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install tools
PACKAGES="zsh nvm hub youtube-dl htop howdoi yarn wifi-password"

for p in $(brew list); do
	PACKAGES=${PACKAGES//$p/}
done

echo "# Installing brew packages"
for PACKAGE in $PACKAGES; do
    echo "- install $PACKAGE"
    brew install $PACKAGE | indent
done

echo ""

echo "# Generate dot files"
for FILE in $(find $DIR/config -type f); do
    FILENAME=$(basename -- "$FILE")
    echo "- add $FILENAME"
    rm -f $HOME/$FILENAME
    ln -s $DIR/config/$FILENAME $HOME/$FILENAME
done
