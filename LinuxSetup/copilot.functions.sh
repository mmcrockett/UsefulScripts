function copilot {
  git-ssh-add
  ghcli &>/dev/null
  trap 'printf "\e]110\a\e]111\a"' RETURN

  local last_dir="${PWD##*/}"
  local session_name="${last_dir}"
  [[ $# -gt 0 ]] && session_name+=" $*"
  if (( ${#session_name} > 100 )); then
    session_name="${session_name:0:101}"
    session_name="${session_name%[[:space:]]*}"
    session_name="${session_name:0:100}"
    while [[ "${session_name}" == *[[:space:]] ]]; do
      session_name="${session_name%?}"
    done
  fi

  llm-bg "$(llm-theme-slug "$@")"

  case "${1:-}" in
    "")
      command copilot --name "${session_name}" ;;
    -*|app|login|help|init|config|update|version|workflow|sessions|memories|plugin|mcp|skill|instruction|lsp|sandbox|completion)
      command copilot "$@" ;;
    *)
      command copilot --name "${session_name}" -i "$*" ;;
  esac
}
