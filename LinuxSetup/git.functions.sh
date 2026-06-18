function gwta {
  local BRANCH="${1}"

  if [[ -n "${BRANCH}" && "${BRANCH}" != -* && "${BRANCH}" != *"${USER}"* ]]; then
    BRANCH="${USER}/${BRANCH}"
  fi

  gwtadd "${BRANCH}"
}
function ghcli {
  "$(brew --prefix)/bin/gh" "$@"
}
function git-ghcli-preflight {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Skipping PR status checks - ensure `gh` is installed with brew and then aliased to `ghcli`."
    return 1
  fi

  local GHCLI_ERR="$(gh --version 2>&1)"

  if [[ "${GHCLI_ERR}" == *"Permission denied"* ]]; then
    brew reinstall gh > /dev/null 2>&1 || (echo "Failed to reinstall gh, check brew and gh installation." && return $?)
  fi
}
function git-pr-status-for-branch {
  local BRANCH="${1}"
  local -a GHCLI_OPTS=(
    "--state" "all"
    "--json" "state,mergedAt,closedAt,url"
    "--template" '{{range .}}#{{.state}}|{{.url}}{{if .mergedAt}} {{.mergedAt}}{{else if .closedAt}} {{.closedAt}}{{end}}{{end}}'
  )

  git-ghcli-preflight || return 1

  command -v ghcli >/dev/null 2>&1 && ghcli pr list --head "${BRANCH}" "${GHCLI_OPTS[@]}"
}
function git-rm-claude-project {
  local BRANCH="${1}"
  local REPO_ROOT="$($_git_cmd rev-parse --show-toplevel 2>/dev/null)"

  [ -z "${REPO_ROOT}" ] && return 0

  local CANDIDATE="${REPO_ROOT}/${BRANCH}"
  local CLAUDE_DIR="${HOME}/.claude/projects/${CANDIDATE//\//-}"

  if [ -d "${CLAUDE_DIR}" ]; then
    rm -rf "${CLAUDE_DIR}" && echo -n " 🧠"
  fi
}
function git-prune-branch-by-pr-status {
  local BRANCH="${1}"
  local PR_STATUS="${2}"

  printf " ↳ %-32s" "${BRANCH}"

  if [ -n "${PR_STATUS}" ]; then
    local PR_STATE="${PR_STATUS%%|*}"
    local PR_INFO="${PR_STATUS##*|}"
    local TRASH=""

    if [[ "${PR_STATE}" == *"MERGED"* || "${PR_STATE}" == *"CLOSED"* ]]; then
      local STATE_ICON="⛔"
      [[ "${PR_STATE}" == *"MERGED"* ]] && STATE_ICON="✔️"

      echo -n " ${STATE_ICON}"
      git branch -D "${BRANCH}" > /dev/null 2>&1 || return $?
      git-branch-history rm "${BRANCH}" > /dev/null 2>&1 || return $?
      TRASH=" 🗑"
      git-rm-claude-project "${BRANCH}"
    elif [[ "${PR_STATE}" == *"OPEN"* ]]; then
      echo -n " 🔀"
    else
      echo -n " ${PR_STATE}"
    fi

    echo -n " ${PR_INFO}${TRASH}"
  else
    echo -n " 🟡"
  fi

  echo
}
function git-rm-merged-local-branches {
  local MAIN_BRANCH="$(git-default-branch-name)"
  local RM_BRANCHES="$($_git_cmd branch --format='%(refname:short)' | grep -v "${MAIN_BRANCH}")"

  git-ghcli-preflight || return 1

  logCmndQuiet git checkout "${MAIN_BRANCH}" || return $?

  echo "=== Checking for merged and closed branches ==="

  for BRANCH in ${RM_BRANCHES}; do
    local PR_STATUS="$(git-pr-status-for-branch "${BRANCH}")"
    git-prune-branch-by-pr-status "${BRANCH}" "${PR_STATUS}" || return $?
  done

  echo "=== completed ==="
}
function git-handle-pr-merged {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="$(git-default-branch-name)"
  local IS_FORK="$(git config --get remote.origin.url | grep "mcrockett")"

  if [ -n "${1}" ]; then
    BRANCH="${1}"
  fi

  logCmndQuiet git checkout ${BRANCH} || return $?

  git-ssh-add

  if [ -z "${IS_FORK}" ]; then
    logCmndQuiet git pull
  else
    logCmnd git-resync-main-repo ${BRANCH} || return $?
  fi
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
    logCmndQuiet git pull upstream ${BRANCH} || return $?
    logCmndQuiet git push origin || return $?
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
function git-push-open-pr {
  local TMP_OUT
  TMP_OUT="$(mktemp)"

  "$_git_cmd" "$@" 2>&1 | tee "${TMP_OUT}"
  local PUSH_STATUS=${PIPESTATUS[0]}

  if [ ${PUSH_STATUS} -eq 0 ]; then
    local PR_URL
    PR_URL="$(
      grep -Eo 'https://github\.com/[[:alnum:]_.-]+/[[:alnum:]_.-]+/(pull/new/[[:alnum:]_./?=&%-]+|compare/[[:alnum:]_./?=&%-]+)' "${TMP_OUT}" \
      | head -n 1
    )"

    if [ -n "${PR_URL}" ]; then
      echo "Opening PR URL: ${PR_URL}"
      open "${PR_URL}"
    fi
  fi

  rm -f "${TMP_OUT}"
  return ${PUSH_STATUS}
}
function git-ssh-add {
  local SSH_STATUS="$(ssh-add -l 2>&1)"

  if [[ "${SSH_STATUS}" == *"Could not open a connection to your authentication agent"* ]]; then
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
  fi

  if [[ "${SSH_STATUS}" != *"github@mmcrockett.com"* ]]; then
    echo "Adding day to ssh key for github..."
    ssh-add -t 14h ~/.ssh/githubpw
  fi
}
function git-is-worktree {
  local GIT_DIR="$($_git_cmd rev-parse --git-dir 2>/dev/null)"

  if [[ "${GIT_DIR}" == *"/.git/worktrees/"* ]]; then
    echo "yes"
  else
    echo ""
  fi
}
function git {
  case $1 in
    checkout)
      local START_BRANCH="$(git-current-branch)"

      if [[ "-" == "${2}" ]]; then
        local NEXT_BRANCH="$(git-branch-history last "${START_BRANCH}")"
        if [ -n "${NEXT_BRANCH}" ]; then
          if [ -z "$(git-is-current-branch "${NEXT_BRANCH}")" ]; then
            "$_git_cmd" checkout "${NEXT_BRANCH}" \
              && git-record-branch-switch "${START_BRANCH}" "${NEXT_BRANCH}"
          else
            echo "Already on branch ${NEXT_BRANCH}."
          fi
        else
          echo "No history found."
        fi
      else
        __scmb_git checkout "${@:2}" && git-record-branch-switch "${START_BRANCH}" "$(git-current-branch)"
      fi
      ;;
    home)
      if [ -n "$(git-is-worktree)" ]; then
        local MAIN_DIR="$("$_git_cmd" worktree list | head -1 | awk '{print $1}')"
        cd "${MAIN_DIR}"
      fi
      "$_git_cmd" checkout "$(git-default-branch-name)"
      ;;
    push)
      git-ssh-add
      git-push-open-pr "$@"
      ;;
    *)
      __scmb_git "$@"
      ;;
  esac
}
function git-take-rebase-commit {
  logCmnd git checkout --ours ${@} && git add ${@}
}
