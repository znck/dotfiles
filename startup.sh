#!/usr/bin/env zsh

DIR="${0:A:h}"

for script in "${DIR}/startup"/*; do
  . "${script}"
done
