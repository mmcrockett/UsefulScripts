readonly LINUX_SETUP_DIR="${HOME}/UsefulScripts.mmcrockett/LinuxSetup"

[[ -s "${LINUX_SETUP_DIR}/bash.functions.sh" ]] && source "${LINUX_SETUP_DIR}/bash.functions.sh"

readonly _SOURCE_LIST=(
  "${LINUX_SETUP_DIR}/bash.alias.sh"
)

readonly _PATH_LIST=(
  "/usr/local/opt/gnu-sed/libexec/gnubin"
  "/usr/local/opt/coreutils/libexec/gnubin"
  #"${HOME}/.rvm/bin"
)

readonly _SOFT_LINK_LIST=(
  "${LINUX_SETUP_DIR}/vimrc.sh:${HOME}/.vimrc"
  "${LINUX_SETUP_DIR}/gitconfig.yml:${HOME}/.gitconfig"
  "${LINUX_SETUP_DIR}/gitignore_global.sh:${HOME}/.gitignore"
  "${LINUX_SETUP_DIR}/gemrc.yml:${HOME}/.gemrc"
  "${HOME}/.bash_profile:${HOME}/.bashrc"
)

sourceFromList "${_SOURCE_LIST[@]}"
addToPathFromList "${_PATH_LIST[@]}"
softLinkFromList "${_SOFT_LINK_LIST[@]}"

setupPrompt "green"

export HISTSIZE=3000
complete -r cd 2>/dev/null
complete -r scp 2>/dev/null

#PERL5LIB="/Users/mcrockett/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
#PERL_LOCAL_LIB_ROOT="/Users/mcrockett/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
#PERL_MB_OPT="--install_base \"/Users/mcrockett/perl5\""; export PERL_MB_OPT;
#PERL_MM_OPT="INSTALL_BASE=/Users/mcrockett/perl5"; export PERL_MM_OPT;

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source "$HOME/perl5/perlbrew/etc/bashrc" # Load perlbrew into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
