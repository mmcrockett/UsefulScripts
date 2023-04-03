function git-default-branch-name {
  local DEFAULT_LIST="master|main|development|production"
  local INFERRED_DEFAULT="$(git config --local --get-regexp branch 2> /dev/null | grep remote | grep -E "(${DEFAULT_LIST})" | cut -d '.' -f 2)"

  if [ -n "${GIT_DEFAULT_BRANCH}" ]; then
    echo "${GIT_DEFAULT_BRANCH}"
  elif [ -n "${INFERRED_DEFAULT}" ]; then
    echo "${INFERRED_DEFAULT}"
  else
    echo "master"
  fi
}
function git-rm-merged-local-branches {
  local RM_BRANCHES="$(git branch --merged | grep "^\s.*mcrockett" | grep -v ".*[^0-9]\+]")"

  for BRANCH in ${RM_BRANCHES}; do
    git-branch-history rm ${BRANCH}
    git branch -d ${BRANCH}
  done
}
function git-handle-pr-merged {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="$(git-default-branch-name)"
  local IS_FORK="$(git config --get remote.origin.url | grep "mcrockett")"

  if [ -n "${1}" ]; then
    BRANCH="${1}"
  fi

  logCmnd git checkout ${BRANCH} || return $?

  if [ -z "${IS_FORK}" ]; then
    logCmnd git pull
  else
    logCmnd git-resync-main-repo ${BRANCH} || return $?
  fi

  logCmnd git-rm-merged-local-branches || return $?
}
function git-rebase-all {
  local MAIN_BRANCH="$(git-default-branch-name)"

  logCmnd git-handle-pr-merged ${MAIN_BRANCH} || return $?

  local REBASE_BRANCHES="$(git branch --list '*mcrockett*')"

  for BRANCH in ${REBASE_BRANCHES}; do
    export GIT_HOOKS_OFF="TRUE"
    logCmnd git checkout ${BRANCH} && git rebase "${MAIN_BRANCH}" || return $?
    unset GIT_HOOKS_OFF
  done

  logCmnd git checkout ${MAIN_BRANCH}
}
function git-rebase-rm-all {
  git-rebase-all
  git-rm-merged-local-branches
}
function git-resync-main-repo {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="$(git-default-branch-name)"
  local IS_BRANCH="no"

  if [ -n "${1}" ]; then
    BRANCH="${1}"
  fi

  if [ -z "$(git-is-current-branch ${BRANCH})" ]; then
    abort "Not on the ${BRANCH} branch."
  else
    logCmnd git fetch upstream || (echo "FIX try 'git remote add upstream git@github.com:Example/Sample.git'" && return $?)
    logCmnd git pull upstream ${BRANCH} || return $?
    logCmnd git push origin || return $?
  fi
}
function git-force-push-branch {
  local DEFAULT_BRANCH="$(git-default-branch-name)"

  if [ -z "$(git-is-current-branch ${DEFAULT_BRANCH})" ]; then
    logCmnd git push -f origin "$(git-current-branch)"
  else
    abort "No force push ${DEFAULT_BRANCH}!"
  fi
}
function git-smash {
  export GIT_HOOKS_OFF="TRUE"
  logCmnd git rebase -i HEAD~${1:-2}
  unset GIT_HOOKS_OFF
}
function git-commit-smash-push {
  logCmnd git commit -m '...' . && git-smash && git-force-push-branch
}
function git-commit-smash {
  logCmnd git commit -m '...' . && git-smash
}
function git-resync-rebase {
  local START_BRANCH="$(git-current-branch)"

  if [[ "$(git-default-branch-name)" != "${START_BRANCH}" ]]; then
    export GIT_HOOKS_OFF="TRUE"
    git-handle-pr-merged && git checkout ${START_BRANCH} && git rebase "$(git-default-branch-name)" || return $?
    unset GIT_HOOKS_OFF

    return $?
  else
    abort "On $(git-default-branch-name), doing nothing."
  fi
}
function git-resync-rebase-push-branch {
  git-resync-rebase && git-force-push-branch
}
function git-current-branch {
  echo "$(git rev-parse --abbrev-ref HEAD)"
}
function git-branch-history {
  if [ -d "${PWD}/.git" ]; then
    local F="${PWD}/.git/CHECKOUT_HISTORY"
    local C_M_D="${1}"
    local BRANCH="${2}"
    local R=""

    if [[ "rm" != "${C_M_D}" ]] && [[ "add" != "${C_M_D}" ]] && [[ "last" != "${C_M_D}" ]]; then
      abort "Unknown option git-branch-history ${C_M_D}"
    fi

    if [ ! -f "${F}" ]; then
      touch "${F}"
    fi

    if [[ "rm" == "${C_M_D}" ]] || [[ "add" == "${C_M_D}" ]]; then
      local T="$(mktemp)"

      grep -v "${BRANCH}" "${F}" > "${T}"
      mv "${T}" "${F}"
    fi

    if [[ "add" == "${C_M_D}" ]]; then
      if [ -n "${BRANCH}" ]; then
        echo "${BRANCH}" >> "${F}"
      fi
    fi

    if [[ "last" == "${C_M_D}" ]]; then
      local LAST=""

      if [ -n "${BRANCH}" ]; then
        LAST="$(grep -v "${BRANCH}" "${F}" | tail -n 1)"
      else
        LAST="$(tail -n 1 ${F})"
      fi

      echo "${LAST}"
    fi
  fi
}
function git-is-current-branch {
  local BRANCH="${1}"

  if [ -n "${BRANCH}" ]; then
    echo "$(git branch | grep "^\*" | grep "${BRANCH}")"
  else
    echo ""
  fi
}
function git-record-branch-switch {
  local FROM="${1}"
  local TO="${2}"

  if [ -n "${FROM}" ]; then
    if [[ "$(git-default-branch-name)" != "${FROM}" ]]; then
      git-branch-history add ${FROM}
    fi
  fi

  if [ -n "${TO}" ]; then
    git-branch-history rm "${TO}"
  fi
}
function git {
  local GIT="$(which git)"
  local GIT_CMD="${1}"
  local GIT_OPT="${2}"

  command -v ${GIT} >/dev/null 2>&1

  if [ "0" -eq "$?" ]; then
    if [[ "checkout" == ${GIT_CMD} ]]; then
      local START_BRANCH="$(git-current-branch)"

      if [[ "-" == ${GIT_OPT} ]]; then
        local NEXT_BRANCH="$(git-branch-history last ${START_BRANCH})"

        if [ -n "${NEXT_BRANCH}" ]; then
          if [ -z "$(git-is-current-branch ${NEXT_BRANCH})" ]; then
            ${GIT} checkout ${NEXT_BRANCH} && git-record-branch-switch "${START_BRANCH}" "${NEXT_BRANCH}"
          else
            echo "Already on branch ${NEXT_BRANCH}."
          fi
        else
          echo "No history found."
        fi
      else
        ${GIT} ${@} && git-record-branch-switch "${START_BRANCH}" "$(git-current-branch)"
      fi
    elif [[ "home" == ${GIT_CMD} ]]; then
      git checkout "$(git-default-branch-name)"
    else
      ${GIT} "${@}"

      if [[ "branch" == ${GIT_CMD} ]] && [[ "" != "${3}" ]]; then
        if [[ "-D" == ${GIT_OPT} ]] || [[ "-d" == ${GIT_OPT} ]]; then
          git-branch-history rm ${3}
        fi
      fi
    fi
  else
    abort "GIT not installed or set incorrectly '${GIT}'"
  fi
}
function git-take-rebase-commit {
  local FILE_TO_PICK="${1}"

  if [ -s "${FILE_TO_PICK}" ]; then
    logCmnd git checkout --ours ${FILE_TO_PICK} && git add ${FILE_TO_PICK}
  fi
}
function git-setup-scm-breeze {
  command -v ${GIT} >/dev/null 2>&1

  if [ "0" -eq "$?" ]; then
    alias gh='git checkout "$(git-default-branch-name)"'
  fi
}
git-setup-scm-breeze
