function gwta {
  local BRANCH="${1}"

  if [[ -n "${BRANCH}" && "${BRANCH}" != -* && "${BRANCH}" != *"${USER}"* ]]; then
    BRANCH="${USER}/${BRANCH}"
  fi

  git worktree add "${BRANCH}" && git checkout "${BRANCH}"
}
function ghcli {
  git-gh-preflight || return $?

  "$(gh-brew)" "$@"
}
function gh-brew {
  echo "$(brew --prefix)/bin/gh"
}
function git-gh-preflight {
  local GH_LOC="$(gh-brew)"

  "${GH_LOC}" --version > /dev/null 2>&1 && return 0

  brew reinstall gh > /dev/null 2>&1 || {
    echo "Failed to reinstall gh, check brew and gh installation."
    return 1
  }

  "${GH_LOC}" --version > /dev/null 2>&1 || {
    echo "Skipping PR status checks - ensure \`gh\` is installed with brew and then aliased to \`ghcli\`."
    return 1
  }
}
function git-rm-worktree-for-branch {
  local BRANCH="${1}"
  local WT_PATH="$($_git_cmd worktree list --porcelain | awk -v want="refs/heads/${BRANCH}" '
    /^worktree / { path = substr($0, 10) }
    /^branch /   { if ($2 == want) { print path; exit } }
  ')"

  if [ -z "${WT_PATH}" ]; then
    return 0
  fi

  if "$_git_cmd" worktree remove "${WT_PATH}" > /dev/null 2>&1; then
    echo -n " 🌳"
    return 0
  else
    echo -n " ⚠️ dirty worktree, skipped"
    return 1
  fi
}
function git-pr-status-for-local-branches {
  local SEARCH=""
  local BRANCH=""

  for BRANCH in "$@"; do
    SEARCH+="head:${BRANCH} "
  done

  [ -z "${SEARCH}" ] && return 0

  ghcli pr list --state all --limit 200 --search "${SEARCH}" \
    --json headRefName,state,url,mergedAt,closedAt \
    --jq 'group_by(.headRefName)
          | map((map(select(.state == "OPEN")) | first)
                // (sort_by(.mergedAt // .closedAt // "") | last))
          | .[]
          | [.headRefName, .state, .url, (.mergedAt // .closedAt // "")] | @tsv'
}
function git-rm-merged-local-branches {
  local SCRIPT="${FUNCNAME[0]}"
  local MAIN_BRANCH="$(git-default-branch-name)"

  if [ -z "${MAIN_BRANCH}" ]; then
    abort "Cannot determine the default branch."
    return 1
  fi

  logCmndQuiet git checkout "${MAIN_BRANCH}" || return $?

  local RM_BRANCHES="$($_git_cmd branch --format='%(refname:short)' | grep -vx "${MAIN_BRANCH}")"
  local PR_TSV=""

  PR_TSV="$(git-pr-status-for-local-branches ${RM_BRANCHES})" || return $?

  echo "=== Checking for merged and closed branches ==="

  local BRANCH=""

  for BRANCH in ${RM_BRANCHES}; do
    local PR_ROW="$(printf '%s\n' "${PR_TSV}" | awk -F'\t' -v b="${BRANCH}" '$1 == b { print; exit }')"
    local PR_STATE="$(printf '%s' "${PR_ROW}" | cut -f2)"
    local PR_INFO="$(printf '%s' "${PR_ROW}" | cut -f3,4 | tr '\t' ' ')"
    local TRASH=""

    printf " ↳ %-32s" "${BRANCH}"

    case "${PR_STATE}" in
      MERGED|CLOSED)
        local STATE_ICON="⛔"
        [ "MERGED" = "${PR_STATE}" ] && STATE_ICON="✔️"

        echo -n " ${STATE_ICON}"

        if ! git-rm-worktree-for-branch "${BRANCH}"; then
          echo
          continue
        fi

        git branch -D "${BRANCH}" > /dev/null 2>&1 || return $?
        git-branch-history rm "${BRANCH}" > /dev/null 2>&1 || return $?
        TRASH=" 🗑"
        ;;
      OPEN)
        echo -n " 🔀"
        ;;
      "")
        echo -n " 🟡"
        ;;
      *)
        echo -n " ${PR_STATE}"
        ;;
    esac

    echo " ${PR_INFO}${TRASH}"
  done

  echo "=== completed ==="
}
function git-cleanup-pr-merged {
  git-handle-pr-merged && git-rm-merged-local-branches
}
function git-handle-pr-merged {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="${1:-$(git-default-branch-name)}"

  if [ -z "${BRANCH}" ]; then
    abort "Cannot determine the default branch."
    return 1
  fi

  logCmndQuiet git checkout "${BRANCH}" || return $?

  git-ssh-add

  logCmndQuiet git pull
}
function git-force-push-branch {
  local SCRIPT="${FUNCNAME[0]}"
  local DEFAULT_BRANCH="$(git-default-branch-name)"
  local CURRENT_BRANCH="$(git-current-branch)"

  if [ -z "${DEFAULT_BRANCH}" ]; then
    abort "Cannot determine the default branch, refusing to force push."
    return 1
  fi

  if [ -z "${CURRENT_BRANCH}" ] || [ "HEAD" = "${CURRENT_BRANCH}" ]; then
    abort "Detached HEAD, refusing to force push."
    return 1
  fi

  if [ "${CURRENT_BRANCH}" = "${DEFAULT_BRANCH}" ]; then
    abort "No force push ${DEFAULT_BRANCH}!"
    return 1
  fi

  logCmnd git push --force-with-lease origin "${CURRENT_BRANCH}"
}
function git-smash {
  local SCRIPT="${FUNCNAME[0]}"
  local STATUS=0

  export GIT_HOOKS_OFF="TRUE"
  logCmnd git rebase -i "HEAD~${1:-2}" || STATUS=$?
  unset GIT_HOOKS_OFF

  return ${STATUS}
}
function git-commit-all {
  local SCRIPT="${FUNCNAME[0]}"
  local MESSAGE="${1:-...}"
  local STATUS=0

  export GIT_HOOKS_OFF="TRUE"
  logCmnd git add -A && logCmnd git commit -m "${MESSAGE}" || STATUS=$?
  unset GIT_HOOKS_OFF

  return ${STATUS}
}
function git-commit-wip {
  git-commit-all '--wip--'
}
function git-commit-smash {
  git-commit-all '...' && git-smash
}
function git-commit-smash-push {
  git-commit-smash && git-force-push-branch
}
function git-resync-rebase {
  local SCRIPT="${FUNCNAME[0]}"
  local START_BRANCH="$(git-current-branch)"
  local MAIN_BRANCH="$(git-default-branch-name)"
  local STATUS=0

  if [ -z "${MAIN_BRANCH}" ]; then
    abort "Cannot determine the default branch."
    return 1
  fi

  if [ "${MAIN_BRANCH}" = "${START_BRANCH}" ]; then
    abort "On ${MAIN_BRANCH}, doing nothing."
    return 1
  fi

  if ! "$_git_cmd" diff --quiet HEAD 2>/dev/null; then
    abort "Uncommitted changes, commit or stash before rebasing."
    return 1
  fi

  export GIT_HOOKS_OFF="TRUE"
  git-handle-pr-merged \
    && git checkout "${START_BRANCH}" \
    && git rebase "${MAIN_BRANCH}" \
    || STATUS=$?
  unset GIT_HOOKS_OFF

  return ${STATUS}
}
function git-resync-rebase-push-branch {
  git-resync-rebase && git-force-push-branch
}
function git-current-branch {
  "$_git_cmd" rev-parse --abbrev-ref HEAD 2>/dev/null
}
function git-ssh-add {
  local KEY=~/.ssh/githubpw
  if [ -f ~/.ssh/github.weinfuse ]; then
    KEY=~/.ssh/github.weinfuse
  fi
  local KEY_FINGERPRINT="$(ssh-keygen -lf "${KEY}" 2>/dev/null | awk '{print $2}')"
  local SSH_STATUS="$(ssh-add -l 2>&1)"

  if [[ "${SSH_STATUS}" == *"Could not open a connection to your authentication agent"* ]]; then
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
    SSH_STATUS="$(ssh-add -l 2>&1)"
  fi

  if [[ -z "${KEY_FINGERPRINT}" || "${SSH_STATUS}" != *"${KEY_FINGERPRINT}"* ]]; then
    echo "Adding day to ssh key for github..."
    ssh-add -t 14h "${KEY}"
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
          if [ "${NEXT_BRANCH}" != "${START_BRANCH}" ]; then
            # Via __scmb_git so a branch living in a worktree cd's there
            # instead of failing as already-checked-out.
            __scmb_git checkout "${NEXT_BRANCH}" \
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
      __scmb_git "$@"
      ;;
    pull)
      git-ssh-add
      __scmb_git "$@"
      ;;
    *)
      __scmb_git "$@"
      ;;
  esac
}
