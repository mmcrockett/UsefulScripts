function prune-claude {
  local FORCE=0
  local DAYS=90
  local ARG
  for ARG in "$@"; do
    case "${ARG}" in
      -f|--force) FORCE=1 ;;
      ''|*[!0-9]*) ;;
      *) DAYS="${ARG}" ;;
    esac
  done

  local PLANS_DIR="${HOME}/.claude/plans"
  local PROJECTS_DIR="${HOME}/.claude/projects"

  if [ "${FORCE}" -eq 1 ]; then
    echo "prune-claude: DELETING items older than ${DAYS}d"
  else
    echo "prune-claude: DRY-RUN (older than ${DAYS}d) — re-run with --force to apply"
  fi

  # 1. In-repo .claude/plans symlinks that are dangling or point at a plan we're
  #    about to prune. Scans ${HOME} broadly; node_modules/.git/Library/.Trash are
  #    pruned only for speed (a repo plan-symlink can never live in them).
  echo "── stale plan symlinks ──"
  find "${HOME}" \
       \( -name node_modules -o -name .git -o -name Library -o -name .Trash \) -prune -o \
       -type l -path '*/.claude/plans/*' \
       -exec sh -c '
         DAYS="$1"; FORCE="$2"; PLANS="$3"; shift 3
         for LINK in "$@"; do
           if [ -e "${LINK}" ]; then
             TGT="$(readlink "${LINK}")"
             case "${TGT}" in
               "${PLANS}"/*) [ -n "$(find "${TGT}" -maxdepth 0 -mtime +"${DAYS}" 2>/dev/null)" ] || continue ;;
               *) continue ;;
             esac
           fi
           if [ "${FORCE}" = 1 ]; then
             rm -f "${LINK}" && echo "  🔗✗ ${LINK}"
           else
             echo "  ${LINK}"
           fi
         done
       ' sh "${DAYS}" "${FORCE}" "${PLANS_DIR}" {} + 2>/dev/null

  # 2. Global plan files older than the threshold.
  echo "── plans (${PLANS_DIR}) ──"
  if [ "${FORCE}" -eq 1 ]; then
    find "${PLANS_DIR}" -maxdepth 1 -type f -name '*.md' -mtime +"${DAYS}" -print -delete 2>/dev/null
  else
    find "${PLANS_DIR}" -maxdepth 1 -type f -name '*.md' -mtime +"${DAYS}" -print 2>/dev/null
  fi

  # 3. Per-project state dirs (sessions + memory) untouched past the threshold.
  echo "── projects (${PROJECTS_DIR}) ──"
  if [ "${FORCE}" -eq 1 ]; then
    find "${PROJECTS_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +"${DAYS}" -print -exec rm -rf {} + 2>/dev/null
  else
    find "${PROJECTS_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +"${DAYS}" -print 2>/dev/null
  fi
}

function claude {
  git-ssh-add
  ghcli &>/dev/null
  trap 'printf "\e]110\a\e]111\a"' RETURN

  local last_dir="${PWD##*/}"

  llm-bg "$(llm-theme-slug "$@")"

  local theme_value="custom:${LLM_THEME_SLUG}"
  [[ "${LLM_THEME_SLUG}" == dark ]] && theme_value=dark
  local claude_theme="{\"theme\":\"${theme_value}\"}"

  if [[ $# -eq 0 ]]; then
    command claude --settings ${claude_theme} --name "${last_dir}"
  elif [[ "$1" == -* ]]; then
    command claude --settings ${claude_theme} "$@"
  else
    command claude --settings ${claude_theme} --name "${last_dir} $*" "$*"
  fi
}
