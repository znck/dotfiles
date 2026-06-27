#!/usr/bin/env bash

link_config() {
  local file filename source_dir target
  source_dir="$ROOT/config"

  info "Linking config"
  while IFS= read -r -d '' file; do
    filename="${file#$source_dir/}"
    target="$HOME/$filename"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source_dir/$filename" ]; then
      skip "$filename"
      continue
    fi

    step "$filename"
    mkdir -p "$(dirname "$target")"
    rm -f "$target"
    ln -s "$source_dir/$filename" "$target"
  done < <(find "$source_dir" -type f -print0)
}
