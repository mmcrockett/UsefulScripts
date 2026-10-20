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
  "#5A6E20 #F2F5E0 light-olive"     # dark
  "#7A3A5A #FAEAF0 light-mauve"     # dark
  "- - dark"                       # built-in preset, no OSC recolor
)

claude_reserved_themes=(
  "#6E2020 #F5E8E8 light-red"
  "#2E5A8C #EAF2FA light-blue"
)

claude_unknown_theme="#3A3A3A #D8D8D8 unknown"

claude_theme_map="${HOME}/.claude/repo-themes"

function claude-command-theme {
  case "$1" in
    /wi-pr-list-awaiting-review) echo light-red ;;
    /wi-pr-list-mine) echo light-blue ;;
  esac
}

function claude-theme-key {
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  basename "$(dirname "${common}")"
}

function claude-theme-mapped {
  local slug key
  [[ -r "${claude_theme_map}" ]] || return 1
  while read -r slug key; do
    if [[ "${key}" == "$1" ]]; then
      echo "${slug}"
      return
    fi
  done < "${claude_theme_map}"
  return 1
}

function claude-theme-pick {
  local key="$1"
  if ! [[ -t 0 && -t 2 ]]; then
    echo unknown
    return
  fi

  local used=" " slug row bg fg r g b fr fgg fb
  if [[ -r "${claude_theme_map}" ]]; then
    while read -r slug _; do
      used+="${slug} "
    done < "${claude_theme_map}"
  fi

  local candidates=()
  for row in "${claude_themes[@]}"; do
    [[ "${used}" == *" ${row##* } "* ]] || candidates+=("${row}")
  done
  (( ${#candidates[@]} )) || candidates=("${claude_themes[@]}")

  printf 'No theme for %s. Pick one (Enter = unknown):\n' "${key}" >&2
  local i=1
  for row in "${candidates[@]}"; do
    read -r bg fg slug <<< "${row}"
    if [[ "${slug}" == "dark" ]]; then
      printf '%3d) %s\n' "${i}" "${slug}" >&2
    else
      printf -v r '%d' "0x${bg:1:2}"
      printf -v g '%d' "0x${bg:3:2}"
      printf -v b '%d' "0x${bg:5:2}"
      printf -v fr '%d' "0x${fg:1:2}"
      printf -v fgg '%d' "0x${fg:3:2}"
      printf -v fb '%d' "0x${fg:5:2}"
      printf '%3d) \e[48;2;%d;%d;%dm\e[38;2;%d;%d;%dm %-18s \e[0m\n' \
        "${i}" "${r}" "${g}" "${b}" "${fr}" "${fgg}" "${fb}" "${slug}" >&2
    fi
    i=$(( i + 1 ))
  done

  local choice
  printf '> ' >&2
  read -r choice < /dev/tty
  if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#candidates[@]} )); then
    slug="${candidates[$(( choice - 1 ))]##* }"
    printf '%s %s\n' "${slug}" "${key}" >> "${claude_theme_map}"
    echo "${slug}"
  else
    echo unknown
  fi
}

function claude-theme-slug {
  local arg slug key
  for arg in "$@"; do
    slug="$(claude-command-theme "${arg}")"
    if [[ -n "${slug}" ]]; then
      echo "${slug}"
      return
    fi
  done

  if key="$(claude-theme-key)"; then
    claude-theme-mapped "${key}" || claude-theme-pick "${key}"
  else
    claude-theme-mapped "${PWD}" || echo dark
  fi
}

function claude-bg {
  local want="${1:-$(claude-theme-slug)}"
  local bg fg slug row found=0
  for row in "${claude_themes[@]}" "${claude_reserved_themes[@]}" "${claude_unknown_theme}"; do
    read -r bg fg slug <<< "${row}"
    if [[ "${slug}" == "${want}" ]]; then
      found=1
      break
    fi
  done
  (( found )) || read -r bg fg slug <<< "${claude_unknown_theme}"

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
  git-ssh-add
  ghcli &>/dev/null
  trap 'printf "\e]110\a\e]111\a"' RETURN

  local last_dir="${PWD##*/}"

  claude-bg "$(claude-theme-slug "$@")"

  local claude_theme="{\"theme\":\"${CLAUDE_THEME_VALUE}\"}"

  if [[ $# -eq 0 ]]; then
    command claude --settings ${claude_theme} --name "${last_dir}"
  elif [[ "$1" == -* ]]; then
    command claude --settings ${claude_theme} "$@"
  else
    command claude --settings ${claude_theme} --name "${last_dir} $*" "$*"
  fi
}

