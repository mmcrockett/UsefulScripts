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

# Set =true to disable the design/assets management features
# export SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT=true

# vi: ft=sh
alias gh='git home'
alias gl8='gl -8'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
alias gdno='gd --name-only'

function git-commit-wip {
  GIT_HOOKS_OFF=true git add -A
  GIT_HOOKS_OFF=true git rm $(git ls-files --deleted) 2> /dev/null
  GIT_HOOKS_OFF=true git commit -m '--wip--'
}
function git-commit-message-from-branch {
  local description="$(gb --show-current)"
  local description_parts=()
  local prefix="💥"
  local story_id=""

  while [[ "${description}" =~ ([[:alnum:]]+)(.*) ]]; do
    word="${BASH_REMATCH[1]}"
    description="${BASH_REMATCH[2]}"

    if [[ "$word" =~ ^[a-zA-Z0-9]{9}$ ]] && [[ "$word" =~ ^[0-9]{2,} ]]; then
      story_id="$word"
    elif [[ "$word" == "${USER}" ]]; then
      username="$word"
    else
      if [[ "$word" == "fix" ]] || [[ "$word" == "bug" ]]; then
        # Randomly choose between beetle and ladybug
        if (( RANDOM % 2 )); then
          prefix="🪲"
        else
          prefix="🐞"
        fi
      fi
      # Check if current word is 'speed' or 'faster'
      if [[ "$word" == "speed" ]] || [[ "$word" == "faster" ]]; then
        # Randomly choose between rocket and racehorse
        if (( RANDOM % 2 )); then
          prefix="🚀"
        else
          prefix="🐎"
        fi
      fi

      description_parts+=("$word")
    fi
  done

  # Join description parts with spaces
  description=$(printf "%s " "${description_parts[@]}" | sed 's/ $//')
  echo "${USER}/${story_id}${prefix}${description}"
}
function gco-story {
  local old_pwd="${PWD}"
  local story_id="nostory"
  local description=""
  local description_parts=()
  local prefix=""
  local new_branch_name=""
  local not_ready=""

  # Check for unstaged changes in both workspaces before switching
  for workspace in "$WORKSPACE_API" "$WORKSPACE_FRONTEND"; do
    cd "$workspace"
    if [[ -n $(git status --short -uno) ]]; then
      echo "Error: Unstaged changes in $(basename "$workspace")"
      not_ready="true"
    fi
  done

  if [[ "$not_ready" == "true" ]]; then
    cd "$old_pwd"
    return 1
  fi

  # Parse arguments: identify story_id by pattern (alphanumeric, 9 chars starts with 2 digit number)
  for arg in "$@"; do
    if [[ "$arg" =~ ^[a-zA-Z0-9]{9}$ ]] && [[ "$arg" =~ ^[0-9]{2,} ]]; then
      story_id="$arg"
    else
      description_parts+=("$arg")
    fi
  done

  # Join description parts with hyphens
  description=$(printf "%s-" "${description_parts[@]}" | sed 's/-$//')
  new_branch_name="${USER}/${story_id}"

  # Build branch name
  if [[ -n "$description" ]]; then
    new_branch_name="${new_branch_name}-${prefix}${description}"
  fi

  for workspace in "$WORKSPACE_API" "$WORKSPACE_FRONTEND"; do
    printf "$(basename "$workspace") => ${new_branch_name}..."
    if cd "$workspace" && gh &> /dev/null && git checkout -b "${new_branch_name}" &> /dev/null; then
      echo "✅"
    else
      echo "❌"
      cd "$old_pwd"
      return 1
    fi
  done

  cd "${old_pwd}"
}
function gci-story {
  local description="$(git-commit-message-from-branch)"

  printf "$(basename "$PWD") => '${description}'"

  if git add -A &> /dev/null && git commit -a -m "${description}" &> /dev/null; then
    echo " ✅"
  else
    echo " ❌"
    return 1
  fi
}
