function abort { echo 1>&2 "${SCRIPT}:!ERROR:" "${@}"; return 1;}
function logArgs { echo 1>&2 "${SCRIPT}:" "${@}"; }
function logCmnd { echo 1>&2 "${SCRIPT}:$(printf ' %q' "${@}")"; "${@}"; }
function directoryExists { if [ ! -d "${1}" ]; then abort "Cannot find directory '${1}'. Ensure directory exists."; fi }
function usage() { if [ -n "${@}" ]; then printf '%s\n' "Usage: ${SCRIPT} ${@}" 1>&2; return 1; fi }

readonly LINUX_SETUP_DIR="${HOME}/UsefulScripts.mmcrockett/LinuxSetup"

readonly _SOURCE_LIST=(
  "${LINUX_SETUP_DIR}/bash.alias.sh"
  "${LINUX_SETUP_DIR}/bash.functions.sh"
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
)

for _SOURCE_FILE_ in "${_SOURCE_LIST[@]}"; do
  if [ -s "${_SOURCE_FILE_}" ]; then
    source ${_SOURCE_FILE_}
  fi
done

for _PATH_LOCATION_ in "${_PATH_LIST[@]}"; do
  if [ -s "${_PATH_LOCATION_}" ]; then
    export PATH="${_PATH_LOCATION_}:${PATH}"
  fi
done

for _SOFT_LINK_PAIR_ in "${_SOFT_LINK_LIST[@]}"; do
  _FILES=(${_SOFT_LINK_PAIR_//:/ })
  _LN_SOURCE="${_FILES[0]}"
  _LN_TARGET="${_FILES[1]}"

  if [ ! -s "${_LN_TARGET}" ]; then
    if [ -s "${_LN_SOURCE}" ]; then
      ln -s ${_LN_SOURCE} ${_LN_TARGET}
    fi
  fi
done

if [ "$TERM" = "linux" ]; then
    export PS1="\[\e[32;1m\]\u@\H > \[\e[0m\]"
else
    export PROMPT_COMMAND='tmp=${PWD%/*/*/*}; if [ ${#tmp} -gt 0 -a "$tmp" != "$PWD" ]; then myPWD=../${PWD:${#tmp}+1}; else myPWD=$PWD; fi'
    export PS1="\[\e]2;\u@\H \$PWD\a\e[01;32m\][\$myPWD]\$\[\e[0m\] "  #green
    #export PS1="\[\e]2;\u@\H \$PWD\a\e[01;36m\][\$myPWD]\$\[\e[0m\] " #teal
    #export PS1="\[\e]2;\u@\H \$PWD\a\e[01;31m\][\$myPWD]\$\[\e[0m\] " #red
fi

export HISTSIZE=3000
complete -r cd
complete -r scp

#PERL5LIB="/Users/mcrockett/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
#PERL_LOCAL_LIB_ROOT="/Users/mcrockett/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
#PERL_MB_OPT="--install_base \"/Users/mcrockett/perl5\""; export PERL_MB_OPT;
#PERL_MM_OPT="INSTALL_BASE=/Users/mcrockett/perl5"; export PERL_MM_OPT;

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source "$HOME/perl5/perlbrew/etc/bashrc" # Load perlbrew into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
