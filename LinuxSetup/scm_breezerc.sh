#
# Design Assets Management Config
# ----------------------------------------------------------------
# Directory where design assets are stored
export root_design_dir="$HOME/Dropbox/Design"
# Directory where symlinks are created within each project
export project_design_dir="design_assets"
# Directories for per-project design assets
export design_base_dirs="Documents Flowcharts Images Backgrounds Logos Icons Mockups Screenshots"
export design_av_dirs="Animations Videos Flash Music Samples"
# Directories for global design assets (not symlinked into projects)
export design_ext_dirs="Fonts IconSets"
export git_skip_shell_completion="yes" 
export git_setup_aliases="no"

# Set =true to disable the design/assets management features
# export SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT=true

# vi: ft=sh
alias gh='git checkout "$(git-default-branch-name)"'

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
function git-branch-history {
  if [ -d "${PWD}/.git" ]; then
    local F="${PWD}/.git/CHECKOUT_HISTORY"
    local C_M_D="${1}"
    local BRANCH="${2}"
    local R=""

    if [ ! -f "${F}" ]; then
      touch "${F}"
    fi

    case $C_M_D in
      add|rm|-d|-D)
        local T="$(mktemp)"

        grep -vw "${BRANCH}" "${F}" > "${T}"
        mv "${T}" "${F}";;
      last)
        local LAST=""

        if [ -n "${BRANCH}" ]; then
          LAST="$(grep -vw "${BRANCH}" "${F}" | tail -n 1)"
        else
          LAST="$(tail -n 1 ${F})"
        fi

        echo "${LAST}";;
      *)
        abort "Unknown option git-branch-history ${C_M_D}";;
    esac


    if [[ "add" == "${C_M_D}" ]]; then
      if [ -n "${BRANCH}" ]; then
        echo "${BRANCH}" >> "${F}"
      fi
    fi
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
