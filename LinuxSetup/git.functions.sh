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
  local RM_BRANCHES="$($_git_cmd branch | grep "^\s.*mcrockett")"
  local MAIN_BRANCH="$(git-default-branch-name)"

  git checkout ${MAIN_BRANCH}

  for BRANCH in ${RM_BRANCHES}; do
    # Continue (skip) if there is no `-` in the cherry output
    git cherry ${BRANCH} ${MAIN_BRANCH} | grep --silent '^-' || continue

    # Continue (skip) if the branch is still on the remote
    git branch --remotes | grep --silent "origin/${BRANCH}" && continue

    git-branch-history rm ${BRANCH}
    git branch -D ${BRANCH}
    echo "REMOVED: ${BRANCH}"
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

  logCmnd git remote prune origin
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
function git-is-current-branch {
  local BRANCH="${1}"

  if [ -n "${BRANCH}" ]; then
    echo "$(git branch | grep "^\*" | grep -w "${BRANCH}")"
  else
    echo ""
  fi
}
function git {
  # Only expand args for git commands that deal with paths or branches
  case $1 in
    commit|blame|add|log|rebase|merge|difftool|switch)
      exec_scmb_expand_args "$_git_cmd" "$@";;
    checkout)
      local START_BRANCH="$(git-current-branch)"

      if [[ "-" == ${2} ]]; then
        local NEXT_BRANCH="$(git-branch-history last ${START_BRANCH})"
        if [ -n "${NEXT_BRANCH}" ]; then
          if [ -z "$(git-is-current-branch ${NEXT_BRANCH})" ]; then
            "$_git_cmd" checkout ${NEXT_BRANCH} && git-record-branch-switch "${START_BRANCH}" "${NEXT_BRANCH}"
          else
            echo "Already on branch ${NEXT_BRANCH}."
          fi
        else
          echo "No history found."
        fi
      else
        exec_scmb_expand_args --relative "$_git_cmd" "$@" && git-record-branch-switch "${START_BRANCH}" "$(git-current-branch)"
      fi;;
    home)
      "$_git_cmd" checkout "$(git-default-branch-name)";;
    diff|rm|reset|restore)
      exec_scmb_expand_args --relative "$_git_cmd" "$@";;
    branch)
      _scmb_git_branch_shortcuts "${@:2}";;
    *)
      "$_git_cmd" "$@";;
  esac
}
function gitold {
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
        exec_scmb_expand_args ${GIT} ${@} && git-record-branch-switch "${START_BRANCH}" "$(git-current-branch)"
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
  logCmnd git checkout --ours ${@} && git add ${@}
}
