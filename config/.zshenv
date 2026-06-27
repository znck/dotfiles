export ZNCK_AGENT_PRIVATE_KEY_PATH="$HOME/.config/znck-agent/private-key.pem"
export ZNCK_AGENT_NAME="znck-agent[bot]"
export ZNCK_AGENT_EMAIL="295982911+znck-agent[bot]@users.noreply.github.com"
export DOTFILES="${HOME}/.dotfiles"

export LANG=en_US.UTF-8
export MANPATH="/usr/local/man:${MANPATH:-}"
export EDITOR='vim'

export BREW_HOME="/opt/homebrew"
export PNPM_HOME="$HOME/.pnpm"
export N_PREFIX="$HOME/.n"
export BUN_INSTALL="$HOME/.bun"

typeset -U path PATH
path=(
  "$DOTFILES/bin"
  "$HOME/.local/bin"
  "/opt/homebrew/opt/ruby/bin"
  "$BUN_INSTALL/bin"
  "$N_PREFIX/bin"
  "$PNPM_HOME"
  "$HOME/.cargo/bin"
  "$BREW_HOME/bin"
  $path
)
export PATH

if [[ ! -o interactive ]]; then
  if [[ -z "${ZNCK_AGENT_MODE:-}" ]]; then
    export ZNCK_AGENT_MODE=1
    export ZNCK_AGENT_MODE_AUTO=1
  fi
elif [[ "${ZNCK_AGENT_MODE_AUTO:-}" = 1 ]]; then
  unset ZNCK_AGENT_MODE
  unset ZNCK_AGENT_MODE_AUTO
fi
