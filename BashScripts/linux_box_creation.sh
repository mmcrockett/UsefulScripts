#!/bin/bash

readonly SCRIPT=`basename "${0}"`
readonly USEFUL_SCRIPTS_MMCROCKETT_DIR="${HOME}/UsefulScripts.mmcrockett"

function abort { echo 1>&2 "${SCRIPT}:!ERROR:" "${@}"; exit 1; }
function logCmnd { echo 1>&2 "${SCRIPT}:$(printf ' %q' "${@}")"; "${@}"; }
function logArgs { echo 1>&2 "${SCRIPT}:" "${@}"; }
function warning { echo 1>&2 "${SCRIPT}:!WARNING:" "${@}"; }
function setupGit {
  local REQUIRED_FILES=(
    ".ssh/github_id_rsa"
    ".ssh/config"
  )
  local FILE_MISSING=""
  local FULL_HOSTNAME="$(hostname -f)"

  for _REQUIRED_FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${HOME}/${_REQUIRED_FILE}" ]; then
      warning "Need to run 'scp ~/${_REQUIRED_FILE} ${FULL_HOSTNAME}:~/${_REQUIRED_FILE}'."
      FILE_MISSING=true
    fi
  done

  if [ -n "${FILE_MISSING}" ]; then
    abort "There are missing files."
  fi

  if [ -z "$(command -v git)" ]; then
    logCmnd sudo apt-get -yqq install git
  fi

  if [ ! -d "${USEFUL_SCRIPTS_MMCROCKETT_DIR}" ]; then
    logCmnd git clone --quiet git@github.com:mmcrockett/UsefulScripts.git ${USEFUL_SCRIPTS_MMCROCKETT_DIR}
  else
    logCmnd cd ${USEFUL_SCRIPTS_MMCROCKETT_DIR} && git pull
  fi
}
function setupEnv {
  local _BASH_LOGIN_FILE="${HOME}/.bash_profile"

  if [ ! -d "${USEFUL_SCRIPTS_MMCROCKETT_DIR}" ]; then
    abort "Can't find '${USEFUL_SCRIPTS_MMCROCKETT_DIR}'."
  fi

  if [ ! -s "${_BASH_LOGIN_FILE}" ]; then
    logCmnd cp ${USEFUL_SCRIPTS_MMCROCKETT_DIR}/LinuxSetup/bash_profile.example.sh ${_BASH_LOGIN_FILE}
    echo "setupPrompt 'teal'" >> ${_BASH_LOGIN_FILE}
  fi

  [[ -s "${USEFUL_SCRIPTS_MMCROCKETT_DIR}/LinuxSetup/bash.profile.sh" ]] && source "${USEFUL_SCRIPTS_MMCROCKETT_DIR}/LinuxSetup/bash.profile.sh"
}
function backupSetup {
  local SYSTEM_FILES=(
    ".bash_profile"
    ".profile"
    ".bashrc"
    ".gitconfig"
    ".alias"
    ".vimrc"
    ".bash_logout"
  )

  backupFromList -d "${SYSTEM_FILES}"
}

setupGit

if [ -s "${USEFUL_SCRIPTS_MMCROCKETT_DIR}/LinuxSetup/bash.profile.sh" ]; then
  source "${USEFUL_SCRIPTS_MMCROCKETT_DIR}/LinuxSetup/bash.profile.sh"
else
  abort "Need to run mmcrockett linux setup first!"
fi

backupSetup
setupEnv
#installRvmAndRubies "ruby-2.2.5"
