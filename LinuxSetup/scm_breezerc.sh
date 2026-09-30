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
alias ghm='git home'
alias gl8='gl -8'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
alias gdno='gd --name-only'

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
