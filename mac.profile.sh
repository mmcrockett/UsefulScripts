source ~/.alias

function abort { echo 1>&2 "${SCRIPT}:!ERROR:" "${@}"; exit 1; }
function logArgs { echo 1>&2 "${SCRIPT}:" "${@}"; }
function logCmnd { echo 1>&2 "${SCRIPT}:$(printf ' %q' "${@}")"; "${@}"; }

if [ "$TERM" = "linux" ]
then
    export PS1="\[\e[32;1m\]\u@\H > \[\e[0m\]"
else
    export PROMPT_COMMAND='tmp=${PWD%/*/*/*}; if [ ${#tmp} -gt 0 -a "$tmp" != "$PWD" ]; then myPWD=../${PWD:${#tmp}+1}; else myPWD=$PWD; fi'
    export PS1="\[\e]2;\u@\H \$PWD\a\e[01;32m\][\$myPWD]\$\[\e[0m\] "  #green
    #export PS1="\[\e]2;\u@\H \$PWD\a\e[01;36m\][\$myPWD]\$\[\e[0m\] " #teal
    #export PS1="\[\e]2;\u@\H \$PWD\a\e[01;31m\][\$myPWD]\$\[\e[0m\] " #red
fi

function removeUnwantedCharacters() {
  local SCRIPT="${FUNCNAME[0]}"
  if [ -z "${1}" ]; then
    abort "Need string to remove characters from."
  else
    local STRIPPED_STRING="$(echo "${1}" | sed -e 's/[ ]*//g')"
    STRIPPED_STRING="$(echo "${STRIPPED_STRING}" | sed -e 's/[ .,://&]/_/g')"
    echo "${STRIPPED_STRING}"
  fi
}

function trim() {
  local SCRIPT="${FUNCNAME[0]}"
  if [ -z "${1}" ]; then
    abort "Need string to trim from."
  else
    local STRIPPED_STRING="${1##*( )}"
    STRIPPED_STRING="${STRIPPED_STRING%%*( )}"
    echo "${STRIPPED_STRING}"
  fi
}

function emptyCamera() {
  local SCRIPT="${FUNCNAME[0]}"
  local VOLUMES=("CANONEOS" "GECamera" "Picasa 3")

  for VOLUME in "${VOLUMES[@]}"; do
    local FULL_VOLUME="/Volumes/${VOLUME}"
    local VOLUME_DIR="${FULL_VOLUME}/DCIM"
    local DATE_FORMAT="$(date "+%Y%m%d")"

    if [ -d "${FULL_VOLUME}" ]; then
      if [ -d "${VOLUME_DIR}" ]; then
        local NEW_DIRECTORY="/Users/mcrockett/Camera/${DATE_FORMAT}"

        if [ ! -d "${NEW_DIRECTORY}" ]; then
          logCmnd mkdir ${NEW_DIRECTORY}
        fi

        logCmnd find ${VOLUME_DIR} -iname "*.jpg" -exec mv {} ${NEW_DIRECTORY} \;
        logCmnd find ${VOLUME_DIR} -iname "*.mov" -exec mv {} ${NEW_DIRECTORY} \;
      else
        logArgs "Path on device not as expected '${VOLUME_DIR}'."
      fi

      logCmnd diskutil eject "${FULL_VOLUME}"
    else
      logArgs "Device not connected '${FULL_VOLUME}'."
    fi
  done
}

function processPodcasts() {
  local SCRIPT="${FUNCNAME[0]}"
  local POD_PLAYER="/Volumes/PODCAST"

  for FULLPATH in "$@"; do
    local FILENAME="${FULLPATH##*/}"
    local DIRECTORY="${FULLPATH%/*}"

    if [ ! -d "${DIRECTORY}" ]; then
      DIRECTORY="."
    fi

    local FILENAME_BASE="${FILENAME%.mp3}"
    local TITLE="$(mp3info -p "%t" "${FULLPATH}")"

    if [ -n "${TITLE}" ]; then
      TITLE="$(removeUnwantedCharacters "${TITLE}")"
      TITLE="$(echo "${TITLE}" | sed -e 's/Title//g')"
    fi

    FILENAME_BASE="$(removeUnwantedCharacters "${FILENAME_BASE}")"
    local FILENAME_SHORT="${DIRECTORY}/${FILENAME_BASE}${TITLE}.short.mp3"
    local FILENAME_FINAL="${DIRECTORY}/${FILENAME_BASE}${TITLE}.short.voice.mp3"

    
    if [[ "${FILENAME_BASE##whatsthepoint}" != "${FILENAME_BASE}" ]]; then
      local START_CUT=57
      local END_CUT=45
    elif [[ "${FILENAME_BASE##fivethirtyeightelections}" != "${FILENAME_BASE}" ]]; then
      local START_CUT=0
      local END_CUT=0
    else
      local START_CUT=57
      local END_CUT=25
    fi

    if [[ "0" == "${START_CUT}" && "0" == "${END_CUT}" ]]; then
      FILENAME_FINAL="${FULLPATH}"
    else
      logCmnd sox  "${FULLPATH}" "${FILENAME_SHORT}" trim ${START_CUT} -${END_CUT}
      logCmnd lame --quiet -V 7 "${FILENAME_SHORT}" "${FILENAME_FINAL}"
    fi

    if [ -d "${POD_PLAYER}" ]; then
      logCmnd mv ${FILENAME_FINAL} ${POD_PLAYER} || return $?
    fi

    if [ -f "${FILENAME_SHORT}" ]; then
      logCmnd rm -f ${FILENAME_SHORT} || return $?
    fi

    if [ -f "${FULLPATH}" ]; then
      logCmnd rm -f "${FULLPATH}" || return $?
    fi
  done

  if [ -d "${POD_PLAYER}" ]; then
    logCmnd diskutil eject "${POD_PLAYER}"
  fi
}

function undoPreviousJava {
  if [ -n "${JAVA_HOME}" ]; then
    export PATH="${PATH//${JAVA_HOME}}"
    unset JAVA_HOME
  fi

  if [ -n "${M2_HOME}" ]; then
    export PATH="${PATH//${M2_HOME}}"
    unset M2_HOME
  fi
}

function set_java {
  local SCRIPT="${FUNCNAME[0]}"

  if [ -z "${1}" ]; then
    abort "Need java version that you want as first parameter."
  else
    undoPreviousJava
    export M2_HOME=/Applications/ride-5.1.4-mac64/apache-maven-3.1.1

    if [[ "${1}" == "8" ]]; then
      export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_71.jdk/Contents/Home
    elif [[ "${1}" == "7" ]]; then
      #export JAVA_HOME=/Applications/ride-5.1.4-mac64/OracleJDK/Contents/Home/jre
      export JAVA_HOME=/Applications/corona-java-1.1.0//jdk-7u45-macosx-x64/Contents/Home
    else
      abort "Unknown java version requested '${1}'."
    fi

    if [ -n "${M2_HOME}" ]; then
      export PATH=$M2_HOME/bin:$PATH
    fi

    if [ -n "${JAVA_HOME}" ]; then
      export PATH=$JAVA_HOME/bin:$PATH
    fi
  fi
}

function rename_mp3_to_mike_format() {
  local SCRIPT="${FUNCNAME[0]}"

  for FULLPATH in "$@"; do
    logArgs "Processing '${FULLPATH}'."
    local FILENAME="${FULLPATH##*/}"
    local FILENAME_BASE="${FILENAME%.mp3}"
    local DIRECTORY="${FULLPATH%/*}"
    local ARTIST="$(trim ${FILENAME_BASE%-*})"
    local TRACK_TITLE="$(trim ${FILENAME_BASE##*-})"
    local NEW_FILE=""
    local ANSWER=""

    printf "Enter artist or return for '${ARTIST}'? "
    read ANSWER
    
    if [[ "" != "${ANSWER}" ]]; then
      ARTIST="${ANSWER}"
    fi

    printf "Enter track title or return for '${TRACK_TITLE}'? "
    read ANSWER
    
    if [[ "" != "${ANSWER}" ]]; then
      TRACK_TITLE="${ANSWER}"
    fi

    NEW_FILE="${DIRECTORY}/$(removeUnwantedCharacters "${ARTIST}")_$(removeUnwantedCharacters "${TRACK_TITLE}").mp3"

    logCmnd mv "${FULLPATH}" "${NEW_FILE}"
    logCmnd mp3info -a "${ARTIST}" -c "" -t "${TRACK_TITLE}" "${NEW_FILE}"
  done
}

set_java 8
export HISTSIZE=3000
complete -r cd
complete -r scp

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
PATH="/Users/mcrockett/perl5/bin${PATH+:}${PATH}"; export PATH;
PATH="/opt/local/bin:/Users/mcrockett/perl5/bin${PATH+:}${PATH}"; export PATH;
PERL5LIB="/Users/mcrockett/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/mcrockett/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/mcrockett/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/mcrockett/perl5"; export PERL_MM_OPT;
PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
MANPATH=/usr/local/opt/gnu-sed/libexec/gnuman/man1:$MANPATH
MANPATH=/usr/local/opt/coreutils/libexec/gnuman/man1:$MANPATH

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
