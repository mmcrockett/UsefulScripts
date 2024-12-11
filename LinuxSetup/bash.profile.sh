readonly SETUP_DIR="${HOME}/UsefulScripts.mmcrockett"
readonly LINUX_SETUP_DIR="${SETUP_DIR}/LinuxSetup"
readonly MAC_SETUP_DIR="${SETUP_DIR}/MacScripts"

[[ -s "${LINUX_SETUP_DIR}/bash.functions.sh" ]] && source "${LINUX_SETUP_DIR}/bash.functions.sh"

readonly _SOURCE_LIST=(
  "${LINUX_SETUP_DIR}/bash.alias.sh"
)

readonly _PATH_LIST=(
  "/usr/local/opt/gnu-sed/libexec/gnubin"
  "/usr/local/opt/coreutils/libexec/gnubin"
)

readonly _SOFT_LINK_LIST=(
  "${LINUX_SETUP_DIR}/vimrc.sh:${HOME}/.vimrc"
  "${LINUX_SETUP_DIR}/gvimrc.sh:${HOME}/.gvimrc"
  "${LINUX_SETUP_DIR}/s3cfg.ini:${HOME}/.s3cfg"
  "${LINUX_SETUP_DIR}/gitconfig.yml:${HOME}/.gitconfig"
  "${LINUX_SETUP_DIR}/gitignore_global.sh:${HOME}/.gitignore"
  "${LINUX_SETUP_DIR}/gemrc.yml:${HOME}/.gemrc"
  "${HOME}/.bash_profile:${HOME}/.bashrc"
)

readonly _SOFT_LINK_MAC_LIST=(
  # "${MAC_SETUP_DIR}/com.mcrockett.backup.plist:${HOME}/Library/LaunchAgents/com.mcrockett.backup.plist"
)

readonly _REPLACE_MAC_LIST=(
  "${MAC_SETUP_DIR}/com.googlecode.iterm2.plist:${HOME}/Library/Preferences/com.googlecode.iterm2.plist"
  "${MAC_SETUP_DIR}/org.vim.MacVim.plist:${HOME}/Library/Preferences/org.vim.MacVim.plist"
)

sourceFromList "${_SOURCE_LIST[@]}"

if [ -z "${IS_DOCKER}" ]; then
  addToPathFromList "${_PATH_LIST[@]}"
  softLinkFromList "${_SOFT_LINK_LIST[@]}"
  installPathogen
  weeklyGitPull "${LINUX_SETUP_DIR}/.."
fi

if [ -n "$(isMac)" ]; then
  softLinkFromList "${_SOFT_LINK_MAC_LIST[@]}"
  export GVIM_NO_OPTS="/opt/homebrew/Cellar/macvim/9.1.0727/bin/mvim"
else
  export GVIM_NO_OPTS="/usr/bin/gvim"
fi

setupPrompt "green"

export HISTSIZE=3000
complete -r cd 2>/dev/null
complete -r scp 2>/dev/null

#PERL5LIB="/Users/mcrockett/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
#PERL_LOCAL_LIB_ROOT="/Users/mcrockett/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
#PERL_MB_OPT="--install_base \"/Users/mcrockett/perl5\""; export PERL_MB_OPT;
#PERL_MM_OPT="INSTALL_BASE=/Users/mcrockett/perl5"; export PERL_MM_OPT;

export NVM_DIR="$HOME/.nvm"
export EDITOR=vim

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source "$HOME/perl5/perlbrew/etc/bashrc" # Load perlbrew into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
