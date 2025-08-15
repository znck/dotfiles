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
if [ ! -d /opt/homebrew ]; then
    echo ""
    echo "# Installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew analytics off
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"
fi

# 4. Install brew packages
echo ""
echo "# Updating brew"
brew update

export PATH="/opt/homebrew/bin:${PATH}"
export HOMEBREW_NO_AUTO_UPDATE=1
for tap in "${BREW_TAPS[@]}"; do
    brew tap "${tap}"
done
for package in "${BREW_PACKAGES[@]}"; do
    if ! $(brew list "${package}" &>/dev/null); then
        echo ""
        echo "# Installing ${package}"
        brew install "${package}"
    fi
done

## 5. Install node
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export NODE_VERSION_MANAGER="/opt/homebrew/bin/n"
echo ""
echo "# Installing node"
${NODE_VERSION_MANAGER} latest


## 6. Install node packages
for package in "${NODE_PACKAGES[@]}"; do
    echo ""
    echo "# Installing ${package}"
    npm install --silent --global "${package}@latest"
done

## 7. Load secrets
echo ""
if ask "Load secrets?"; then
    echo "# Loading secrets"
    SECRET_FILES=($(secrets ls))
    for SECRET_FILE in "${SECRET_FILES[@]}"; do
        ask "Load ${SECRET_FILE}" && secrets load --key="${SECRET_FILE}" "${SECRET_FILE}"
    done
fi

## Configure GnuPG
defaults write org.gpgtools.common DisableKeychain -bool yes
defaults write org.gpgtools.common UseKeychain -bool no
gpgconf --kill gpg-agent

## Configure Pinentry
/opt/homebrew/bin/pinentry-touchid -fix

## Done
echo ""
echo "Done. Start a new terminal session!"
