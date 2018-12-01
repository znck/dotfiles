#!/usr/bin/env sh

function keep_running {
  echo "Command: $*"
  RET=1
  while [ ${RET} -ne 0 ]; do
    $("$*")
    RET=$?
    echo "Process Interrupted. Restarting in 3s..."
    sleep 3
  done
}

alias keep-running=keep_running
