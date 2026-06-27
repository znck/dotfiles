#!/usr/bin/env zsh

typeset -g __dotfiles_base_rprompt="$RPROMPT"

__git_commit_author_prompt() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  local default_name default_email author_name author_email author_label
  default_name="$(git config --global --get user.name 2>/dev/null)"
  default_email="$(git config --global --get user.email 2>/dev/null)"
  author_name="$(git config --get user.name 2>/dev/null)"
  author_email="$(git config --get user.email 2>/dev/null)"

  if [[ "$author_name" == "$default_name" && "$author_email" == "$default_email" ]]; then
    return
  fi

  author_label="${author_name:-$author_email}"
  [[ -n "$author_label" ]] || return
  print -r -- "%F{yellow}author: ${author_label}%f"
}

__update_git_commit_author_prompt() {
  local author_prompt
  author_prompt="$(__git_commit_author_prompt)"

  if [[ -n "$author_prompt" ]]; then
    if [[ -n "$__dotfiles_base_rprompt" ]]; then
      RPROMPT="${__dotfiles_base_rprompt} ${author_prompt}"
    else
      RPROMPT="$author_prompt"
    fi
  else
    RPROMPT="$__dotfiles_base_rprompt"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __update_git_commit_author_prompt
