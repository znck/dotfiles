export ZSH_DISABLE_COMPFIX=true
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

ZSH_THEME="robbyrussell"
plugins=(git)

export UPDATE_ZSH_DAYS=13
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"

source "$ZSH/oh-my-zsh.sh"
source "$DOTFILES/startup.sh"
