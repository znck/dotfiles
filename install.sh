#!/usr/bin/env sh

DIR="$(dirname ${0})" # Get script directory.

for script in "${DIR}/scripts"/*; do
  . "${script}"
done
