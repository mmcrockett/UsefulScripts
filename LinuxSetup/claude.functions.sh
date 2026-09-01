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

claude_themes=(
  "#3B0A55 #E8E8E8 violet"          # dark
  "#0A2C4E #E8E8E8 blue"            # dark
  "#0F3311 #E8E8E8 green"           # dark
  "#3A3405 #E8E8E8 olive"           # dark
  "#3E1E04 #E8E8E8 amber"           # dark
  "#320A2C #E8E8E8 magenta"         # dark
  "#123A3A #E8E8E8 cyan"            # dark
  "#F4ECD8 #2A2620 paper"           # light
  "#D8E4F0 #1A2633 cool-paper"      # light
  "#F0E0DA #33221E blush-paper"     # light
  "#E8E0F0 #261A33 lavender-paper"  # light
  "#5A2A6E #F0F0F0 light-violet"    # dark
  "#1F5A4E #F0F0F0 light-teal"      # dark
  "#6E5410 #F5F0E0 light-amber"     # dark
  "#6E2020 #F5E8E8 light-red"       # dark
  "#2E5A8C #EAF2FA light-blue"      # dark
  "#5A6E20 #F2F5E0 light-olive"     # dark
  "#7A3A5A #FAEAF0 light-mauve"     # dark
  "- - dark"                       # built-in preset, no OSC recolor
)

function claude-bg {
  local dir="${1:-$PWD}"
  local idx=$(( $(cksum <<< "$dir" | cut -d ' ' -f 1) % ${#claude_themes[@]} ))
  local bg fg slug
  read -r bg fg slug <<< "${claude_themes[$idx]}"

  if [[ "$slug" == "dark" ]]; then
    printf '\e]110\a\e]111\a'
    CLAUDE_THEME_VALUE="dark"
  else
    printf '\e]11;%s\e\\' "$bg"
    printf '\e]10;%s\e\\' "$fg"
    CLAUDE_THEME_VALUE="custom:${slug}"
  fi
}

function claude {
  trap 'printf "\e]110\a\e]111\a"' RETURN

  local last_dir="${PWD##*/}"

  if [[ $# -eq 0 ]]; then
    claude-bg
    command claude --settings "{\"theme\":\"${CLAUDE_THEME_VALUE}\"}" --name "${last_dir}"
  elif [[ "$1" == -* ]]; then
    command claude "$@"
  else
    claude-bg
    command claude --settings "{\"theme\":\"${CLAUDE_THEME_VALUE}\"}" --name "${last_dir} $*" "$*"
  fi
}

