llm_themes=(
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

llm_reserved_themes=(
  "#6E2020 #F5E8E8 light-red"
  "#2E5A8C #EAF2FA light-blue"
)

llm_unknown_theme="#3A3A3A #D8D8D8 unknown"

# Keep existing saved mappings at their original location.
llm_theme_map="${HOME}/.claude/repo-themes"

function llm-command-theme {
  case "$1" in
    /wi-pr-list-awaiting-review) echo light-red ;;
    /wi-pr-list-mine) echo light-blue ;;
  esac
}

function llm-theme-key {
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  basename "$(dirname "${common}")"
}

function llm-theme-mapped {
  local slug key
  [[ -r "${llm_theme_map}" ]] || return 1
  while read -r slug key; do
    if [[ "${key}" == "$1" ]]; then
      echo "${slug}"
      return
    fi
  done < "${llm_theme_map}"
  return 1
}

function llm-theme-pick {
  local key="$1"
  if ! [[ -t 0 && -t 2 ]]; then
    echo unknown
    return
  fi

  local used=" " slug row bg fg r g b fr fgg fb
  if [[ -r "${llm_theme_map}" ]]; then
    while read -r slug _; do
      used+="${slug} "
    done < "${llm_theme_map}"
  fi

  local candidates=()
  for row in "${llm_themes[@]}"; do
    [[ "${used}" == *" ${row##* } "* ]] || candidates+=("${row}")
  done
  (( ${#candidates[@]} )) || candidates=("${llm_themes[@]}")

  printf 'No theme for %s. Pick one (0 = none, Enter = unknown):\n' "${key}" >&2
  read -r bg fg slug <<< "${llm_unknown_theme}"
  printf -v r '%d' "0x${bg:1:2}"
  printf -v g '%d' "0x${bg:3:2}"
  printf -v b '%d' "0x${bg:5:2}"
  printf -v fr '%d' "0x${fg:1:2}"
  printf -v fgg '%d' "0x${fg:3:2}"
  printf -v fb '%d' "0x${fg:5:2}"
  printf '%3d) \e[48;2;%d;%d;%dm\e[38;2;%d;%d;%dm %-18s \e[0m\n' \
    0 "${r}" "${g}" "${b}" "${fr}" "${fgg}" "${fb}" none >&2
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
  if [[ "${choice}" == 0 ]]; then
    printf 'none %s\n' "${key}" >> "${llm_theme_map}"
    echo none
  elif [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#candidates[@]} )); then
    slug="${candidates[$(( choice - 1 ))]##* }"
    printf '%s %s\n' "${slug}" "${key}" >> "${llm_theme_map}"
    echo "${slug}"
  else
    echo unknown
  fi
}

function llm-theme-slug {
  local arg slug key
  for arg in "$@"; do
    slug="$(llm-command-theme "${arg}")"
    if [[ -n "${slug}" ]]; then
      echo "${slug}"
      return
    fi
  done

  if key="$(llm-theme-key)"; then
    llm-theme-mapped "${key}" || llm-theme-pick "${key}"
  else
    llm-theme-mapped "${PWD}" || echo dark
  fi
}

function llm-bg {
  local want="${1:-$(llm-theme-slug)}"
  local bg fg slug row found=0
  [[ "${want}" == none ]] && want=unknown
  for row in "${llm_themes[@]}" "${llm_reserved_themes[@]}" "${llm_unknown_theme}"; do
    read -r bg fg slug <<< "${row}"
    if [[ "${slug}" == "${want}" ]]; then
      found=1
      break
    fi
  done
  (( found )) || read -r bg fg slug <<< "${llm_unknown_theme}"
  LLM_THEME_SLUG="${slug}"

  if [[ "$slug" == "dark" ]]; then
    printf '\e]110\a\e]111\a'
  else
    printf '\e]11;%s\e\\' "$bg"
    printf '\e]10;%s\e\\' "$fg"
  fi
}

