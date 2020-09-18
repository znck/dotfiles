#!/usr/bin/env sh

set -e

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

echo "# My dotfiles"
cd "$(dirname ${0})"
DIR="$(pwd)" # Get script directory.
cd -

if ! $(isBinary brew); then
    echo ""
    echo "# Install brew"
    command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

if ! [[ -d "${HOME}/.oh-my-zsh" ]]; then
    echo ""
    echo "# Install oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo ""
echo "# Installing brew packages"
PACKAGES="zsh hub node n"
export HOMEBREW_NO_AUTO_UPDATE=1
for PACKAGE in $PACKAGES; do
    if ! $(isBinary ${PACKAGE}); then
        echo "- install $PACKAGE"
        brew install $PACKAGE | indent
    fi
done

echo ""
echo "# Installing npm packages"
PACKAGES=("yarn" "pnpm" "prettier")
for PACKAGE in $PACKAGES; do
    if ! $(isBinary ${PACKAGE}); then
        echo "- install $PACKAGE"
        $(brew --prefix)/bin/npm install --global $PACKAGE | indent
    fi
done

if ! [[ -d /usr/local/n ]]; then
    sudo mkdir -p /usr/local/n
    sudo chown -R $(whoami) /usr/local/n
fi

if ! [[ -d "/Applications/Visual Studio Code.app" ]]; then
    echo ""
    echo "# Downloading VS Code"
    curl -SL https://update.code.visualstudio.com/latest/darwin/stable | tar -xvz - -C /Applications/
    # TODO: Set VS Code settings sync
fi

if ! [[ -d "/Applications/Docker.app" ]]; then
    echo ""
    echo "# Downloading Docker"
    curl -o "${HOME}/Downloads/Docker.dmg" -SL https://download.docker.com/mac/stable/Docker.dmg
    open "${HOME}/Downloads/Docker.dmg"
    cp -a "/Volumes/Docker/Docker.app" "/Applications"
    osascript -e 'tell application "Finder" to eject "Docker"'
fi

# TODO: Get ssh key and gpg file from iCloud

echo ""
echo "# Setup npm"
npm config set init.author.name "Rahul Kadyan"
npm config set init.author.email "hey@znck.me"
npm config set init.author.url "https://znck.me"
npm config set init.license "MIT"
npm config set init.version "0.0.0"

echo ""
echo "# Generate dot files"
for FILE in $(find "$DIR/config" -type f); do
    FILENAME=$(basename -- "$FILE")
    echo "- add $FILENAME"
    rm -f $HOME/$FILENAME
    ln -s $DIR/config/$FILENAME $HOME/$FILENAME
done
