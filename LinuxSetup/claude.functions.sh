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

# Curated dark backgrounds, one per hue region, all readable as a terminal background.
claude_bg_shades=(
  "#14203F"
  "#06302E"
  "#0F2A12"
  "#2A2205"
  "#2E1405"
  "#320A16"
  "#2C0A2C"
  "#3B0A55"
  "#1C0F52"
  "#2B2E35"
)

# Emit an OSC 11 background color chosen from claude_bg_shades by hashing a path.
function claude-bg {
  local dir="${1:-$PWD}"
  local idx=$(( $(cksum <<< "$dir" | cut -d ' ' -f 1) % ${#claude_bg_shades[@]} ))
  printf '\e]11;%s\e\\' "${claude_bg_shades[$idx]}"
}

function claude {
  trap 'printf "\e]111\a"' RETURN
  claude-bg

  local last_dir="${PWD##*/}"

  if [[ $# -gt 0 && "$1" != -* ]]; then
    command claude --name "${last_dir} $*" "$*"
  else
    command claude --name "${last_dir}" "$@"
  fi
}

