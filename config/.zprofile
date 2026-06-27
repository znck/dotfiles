export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

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
