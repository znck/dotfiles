#!/usr/bin/env sh

set -e

echo "# My dotfiles"
cd "$(dirname ${0})"
DIR="$(pwd)" # Get script directory.
cd -

source "${DIR}/deps.sh"
source "${DIR}/scripts/helpers.sh"

## 1. Symlink dotfiles
echo ""
echo "# Generate dot files"
SOURCE_DIR="$DIR/config"
for FILE in $(find $SOURCE_DIR -type f); do
    FILENAME=$(relative "${SOURCE_DIR}" "${FILE}")
    echo "- add ${FILENAME}"
    mkdir -p $(dirname "${HOME}/${FILENAME}")
    rm -f "${HOME}/${FILENAME}"
    ln -s "${SOURCE_DIR}/${FILENAME}" "${HOME}/${FILENAME}"
done

## 2. Install ZSH
if [ ! -d $HOME/.oh-my-zsh ]; then
    echo ""
    echo "# Installing oh-my-zsh"
    export KEEP_ZSHRC="yes"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

## 3. Install brew
if [ ! -d $HOME/.homebrew ]; then
    echo ""
    echo "# Installing brew"
    git clone https://github.com/Homebrew/brew $HOME/.homebrew
    eval "$($HOME/.homebrew/bin/brew shellenv)"
    brew analytics off
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"
fi

# 4. Install brew packages
echo ""
echo "# Updating brew"
brew update

export PATH="${HOME}/.homebrew/bin:${PATH}"
export HOMEBREW_NO_AUTO_UPDATE=1
for tap in "${BREW_TAPS[@]}"; do
    brew tap "${tap}"
done
for package in "${BREW_PACKAGES[@]}"; do
    if ! $(isBinary "${package}"); then
        echo ""
        echo "# Installing ${package}"
        brew install "${package}"
    fi
done

## 5. Install node
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export NODE_VERSION_MANAGER="${HOME}/.homebrew/bin/n"
if ! $(isBinary node); then
    echo ""
    echo "# Installing node"
    ${NODE_VERSION_MANAGER} latest
fi

## 6. Install node packages
echo ""
echo "# Updating node"
$NODE_VERSION_MANAGER latest
for package in "${NODE_PACKAGES[@]}"; do
    echo ""
    echo "# Installing ${package}"
    npm install --silent --global "${package}@latest"
done

## 7. Load secrets
echo ""
echo "# Loading secrets"
SECRET_FILES=($(secrets ls))
for SECRET_FILE in "${SECRET_FILES[@]}"; do
    echo " - ${SECRET_FILE}"
    secrets load --key="${SECRET_FILE}" "${SECRET_FILE}"
done

## Configur GnuPG
defaults write org.gpgtools.common DisableKeychain -bool no 
defaults write org.gpgtools.common UseKeychain -bool yes
gpgconf --kill gpg-agent                                   

## Done
echo ""
echo "Done. Start a new terminal session!"
