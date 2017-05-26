function resizeImages() {
  local SCRIPT="${FUNCNAME[0]}"
  local DIRECTORY="${1}"
  local MAXSIZE="${2}"

  if [ -z "${MAXSIZE}" ]; then
    MAXSIZE=800;
  fi

  directoryExists "${DIRECTORY}" || return 1

  logCmnd mkdir -p ${DIRECTORY}/resized
  logCmnd rename -f 's/\.JPG$/.jpg/' ${DIRECTORY}/*.JPG
  logCmnd cp ${DIRECTORY}/*.jpg ${DIRECTORY}/resized
  logCmnd sips -Z $MAXSIZE ${DIRECTORY}/resized/*.jpg
}

function removeUnwantedCharacters() {
  local SCRIPT="${FUNCNAME[0]}"
  if [ -z "${1}" ]; then
    abort "Need string to remove characters from."
  else
    local STRIPPED_STRING="$(echo "${1}" | sed -e 's/[ ]*//g')"
    STRIPPED_STRING="$(echo "${STRIPPED_STRING}" | sed -e 's/[ .,''://&]/_/g')"
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

function git-resync-main-repo {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="master"
  local IS_BRANCH="no"

  if [ -n "${1}" ]; then
    BRANCH="${1}"
  fi

  IS_BRANCH="$(git branch | grep "\*" | grep "${BRANCH}")"

  if [ -z "${IS_BRANCH}" ]; then
    abort "Not on the ${BRANCH} branch."
  else
    logCmnd git fetch upstream || (echo "FIX try 'git remote add upstream git@github.com:Example/Sample.git'" && return $?)
    logCmnd git pull upstream ${BRANCH} || return $?
    logCmnd git push origin || return $?
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
    local ARTIST="$(mp3info -p "%a" "${FULLPATH}")"
    local TRACK_TITLE="$(mp3info -p "%t" "${FULLPATH}")"
    local NEW_FILE=""
    local ANSWER=""

    if [ -z "${TRACK_TITLE}" ]; then
      TRACK_TITLE="$(trim ${FILENAME_BASE##*-})"
    fi

    if [ -z "${ARTIST}" ]; then
      ARTIST="$(trim ${FILENAME_BASE%-*})"
    fi

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

function find-grep() {
  local SCRIPT="${FUNCNAME[0]}"
  local _GREP=""
  local _GREPARGS="IH"
  local _FILEGLOB=""
  local _DIRECTORY="${PWD}"
  local _USAGE_MSG=' [-n <fileglob> -g <grep arguments> <directory>] <grepword> Calls find with grep options.
    -n <fileglob> Is passed to -name option, if missing causes -type f
    -g <grepargs> Defaults to -IH.
       <directory> Defaults to PWD.'

  for (( OPTIND=0; OPTIND <= ${#@}; ++i )); do
    while getopts "n:g:" option; do
      case "${option}" in
        n)
          _FILEGLOB=${OPTARG}
          ;;
        g)
          _GREPARGS="${OPTARG}"
          ;;
        *)
          abort "Invalid option '${OPTARG}'."
          usage "${_USAGE_MSG}"
          _USAGE_MSG=""
          ;;
      esac
    done

    if [ $OPTIND -le ${#@} ]; then
      local _NOOPTARG="${!OPTIND}"

      if [ -d "${_NOOPTARG}" ]; then
        _DIRECTORY="${_NOOPTARG}"
      elif [ -z "${_GREP}" ]; then
        _GREP="${!OPTIND}"
      else
        _GREP="${_GREP} ${!OPTIND}"
      fi
    fi

    OPTIND=$((OPTIND+1))
  done

  if [ -z "${_GREP}" ]; then
    abort "Something to grep is required as an argument."
    usage "${_USAGE_MSG}"
    _USAGE_MSG=""
  fi

  if [ ! -d "${_DIRECTORY}" ]; then
    abort "Directory not valid. '${_DIRECTORY}'."
    usage "${_USAGE_MSG}"
    _USAGE_MSG=""
  fi

  if [ -n "${_USAGE_MSG}" ]; then
    if [ -z "${_FILEGLOB}" ]; then
      cond=('-type' 'f')
    else
      cond=('-name' "${_FILEGLOB}")
    fi

    logCmnd find ${_DIRECTORY} "${cond[@]}" -exec grep -${_GREPARGS} "${_GREP}" {} \;
  fi
}
