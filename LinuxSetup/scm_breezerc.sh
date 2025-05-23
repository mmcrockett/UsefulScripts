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
alias gh='git checkout "$(git-default-branch-name)"'
alias gl8='gl -8'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'

function git-commit-wip {
  GIT_HOOKS_OFF=true git add -A
  GIT_HOOKS_OFF=true git rm $(git ls-files --deleted) 2> /dev/null
  GIT_HOOKS_OFF=true git commit -m '--wip--'
}
