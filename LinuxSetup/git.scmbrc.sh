#
# Git File Shortcuts Config
# ----------------------------------------------
# - Set your preferred prefix for env variable file shortcuts.
#   (I chose 'e' because it is easy to slide your finger to it from '$'.)
export GIT_ENV_CHAR="e"
# - Max changed files before reverting to 'git status'. git_status_shortcuts() will be slower for lots of changed files.
export GS_MAX_CHANGES="150"
# - When using the git_add_shortcuts() command, automatically invoke 'git rm' to remove deleted files?
export GA_AUTO_REMOVE="yes"

# - Set the following option to 'no' if you want to use your existing git aliases
#   instead of overwriting them.
#   Note: Bash tab completion will not be automatically set up for your aliases if you disable this option.
export GIT_SETUP_ALIASES="yes"

# - Set the following option to 'yes' if you want to turn off shell completion setup
export GIT_SKIP_SHELL_COMPLETION="yes"

# Git Index Config
# ----------------------------------------------
# Repos will be automatically added from this directory.
export GIT_REPO_DIR="$HOME/code"
# Add the full paths of any extra repos to GIT_REPOS, separated with ':'
# e.g. "/opt/rails/project:/opt/rails/another project:$HOME/other/repo"
export GIT_REPOS=""
export GIT_STATUS_COMMAND="git_status_shortcuts"
# Alias
git_index_alias="c"    # Switch to a repo in the (c)ode directory


# Git Aliases
# ----------------------------------------------
git_alias="g"

# 1. 'SCM Breeze' functions
git_status_shortcuts_alias="gs"
git_add_shortcuts_alias="ga"
exec_scmb_expand_args_alias="ge"
git_show_files_alias="gsf"
git_commit_all_alias="gca"
git_grep_shortcuts_alias="gtrep"
# 2. Commands that handle paths (with shortcut args expanded)
git_checkout_alias="gco"
git_checkout_branch_alias="gcb"
git_commit_alias="gc"
git_commit_verbose_alias="gcv"
git_reset_alias="grs"
git_reset_hard_alias="grsh"
git_rm_alias="grm"
git_blame_alias="gbl"
git_diff_alias="gd"
git_diff_no_whitespace_alias="gdnw"
git_diff_file_alias="gdf"
git_diff_word_alias="gdw"
git_diff_cached_alias="gdc"
git_difftool_alias="gdt"
git_mergetool_alias="gmt"
# 3. Standard commands
git_clone_alias="gcl"
git_fetch_alias="gf"
git_fetch_all_alias="gfa"
git_fetch_and_rebase_alias="gfr"
git_pull_alias="gpl"
git_pull_rebase_alias="gplr"
git_push_alias="gps"
git_push_force_alias="gpsf"
git_pull_then_push_alias="gpls"
git_status_original_alias="gst"
git_status_short_alias="gss"
git_clean_alias="gce"
git_clean_force_alias="gcef"
git_add_all_alias="gaa"
git_add_patch_alias="gap"
git_add_updated_alias="gau"
git_commit_amend_alias="gcm"
git_commit_amend_no_msg_alias="gcmh"
git_commit_no_msg_alias="gch"
git_remote_alias="gr"
git_branch_alias="gb"
git_branch_all_alias="gba"
git_branch_move_alias="gbm"
git_branch_delete_alias="gbd"
git_branch_delete_force_alias="gbD"
git_rebase_alias="grb"
git_rebase_interactive_alias="grbi"
git_rebase_alias_continue="grbc"
git_rebase_alias_abort="grba"
git_reset_last_commit="grsl"
git_merge_alias="gm"
git_merge_no_fast_forward_alias="gmnff"
git_merge_only_fast_forward_alias="gmff"
git_cherry_pick_alias="gcp"
git_log_alias="gl"
git_log_all_alias="gla"
git_log_stat_alias="glst"
git_log_graph_alias="glg"
git_show_alias="gsh"
git_show_summary="gsm"  # (gss taken by git status short)
git_stash_alias="gash"
git_stash_apply_alias="gasha"
git_stash_pop_alias="gashp"
git_stash_list_alias="gashl"
git_tag_alias="gt"
git_submodule_update_alias="gsu"
git_submodule_update_rec_alias="gsur"
git_top_level_alias="gtop"
git_whatchanged_alias="gwc"
git_apply_alias="gapp"
git_switch_alias="gsw"
git_restore_alias="grt"
# Hub aliases (https://github.com/github/hub)
git_pull_request_alias="gpr"


# Git Keyboard Shortcuts
# ----------------------------------------------
# Keyboard shortcuts are on by default. Set this to 'false' to disable them.
git_keyboard_shortcuts_enabled="true"
git_commit_all_keys="\C-x "               # CTRL+x, SPACE
git_add_and_commit_keys="\C-xc"           # CTRL+x, c
git_commit_all_with_ci_skip_keys="\C-xv"  # CTRL+x, v    (Appends [ci skip] to message)
git_add_and_amend_commit_keys="\C-xz"     # CTRL+x, z


# Shell Command Wrapping
# ----------------------------------------------
# Expand numbered args for common shell commands
shell_command_wrapping_enabled="true"
# Here you can tweak the list of wrapped commands.
scmb_wrapped_shell_commands=(vim emacs gedit cat rm cp mv ln cd ls less subl code)
# Add numbered shortcuts to output of ls -l, just like 'git status'
shell_ls_aliases_enabled="true"

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
        abort "`git-branch-history` unknown option ${C_M_D}";;
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
