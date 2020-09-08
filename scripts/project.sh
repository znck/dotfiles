#!/usr/bin/env sh

if [ -z "${WORKSPACE_DIRECTORY}" ]; then
  WORKSPACE_DIRECTORY="${HOME}/Workspace"
fi

export WORK_PROJECTS="${WORKSPACE_DIRECTORY}"
export OPEN_SOURCE_DIRECTORY="${WORKSPACE_DIRECTORY}/OpenSource"
export MY_PROJECTS="${WORKSPACE_DIRECTORY}/znck"
export EXPERIMENTAL_PROJECTS="${WORKSPACE_DIRECTORY}/Experiments"

DIRS=("${OPEN_SOURCE_DIRECTORY}" "${MY_PROJECTS}" "${WORK_PROJECTS}" "${EXPERIMENTAL_PROJECTS}")

# Create required directories.
for i in "${DIRS[@]}"; do
  if [ ! -d "${i}" ]; then
    echo "Creating directory - ${i}"
    mkdir -p "${i}"
  fi
done

function __open_project {
  local DIR="${1}"

  if [ ! -d "${1}" ]; then
    echo 'No project found.'
  else
    cd "${1}"
  fi
}

function __project {
  PROJECT="${1}"
  
  if [ ! -z "${4}" ]; then
    PROJECT="${1}/${4}"

    __open_project "${PROJECT}" "${2}" "${3}" "${4}"
  else
    cd "${PROJECT}"
  fi

  if [ ! -z "${5}" ]; then
    "${5}" "${PROJECT}"
  fi
}

function work {
  __project "${WORK_PROJECTS}" "${UPSTREAM_WORK:-'github'}" "${UPSTREAM_WORK_USER}" "$@"
}

function me {
  __project "${MY_PROJECTS}" github znck "$@"
}

function os {
  __project "${OPEN_SOURCE_DIRECTORY}/${1}" github "$@"
}

function experiment {
  __project "${EXPERIMENTAL_PROJECTS}" "" "" "$@"
}
