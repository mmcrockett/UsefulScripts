function identifier {
  local IDENTIFIER="sh"

  if [ -n "${SCRIPT}" ]; then
    IDENTIFIER="${SCRIPT}"
  fi

  echo "${IDENTIFIER}"
}
# git-resync doesn't work for exit
function abort { echo 1>&2 "$(identifier):!ERROR:" "${@}"; return 1;}
function information { if [ -t 1 ]; then echo 1>&2 "$(identifier):" "${@}"; fi; }
function warning { echo 1>&2 "$(identifier):!WARNING:" "${@}"; }
function logArgs { echo 1>&2 "$(identifier):" "${@}"; }
function logCmnd { echo 1>&2 "$(identifier):$(printf ' %q' "${@}")"; "${@}"; }
function directoryExists { if [ ! -d "${1}" ]; then abort "Cannot find directory '${1}'. Ensure directory exists."; fi }
function usage() { if [ -n "${@}" ]; then printf '%s\n' "Usage: ${SCRIPT} ${@}" 1>&2; return 1; fi }
function weeklyGitPull {
  local CUR_DIR="${PWD}"
  local REPO="${1}"
  local GIT_FOLDER="${REPO}/.git"
  local GIT_FETCH_HEAD="${GIT_FOLDER}/FETCH_HEAD"

  if [ -n "${WEEKLY_GIT_PULL_OFF}" ]; then
    information "Weekly git pull turned off for '${REPO}'."
  else
    if [ ! -d "${REPO}" ]; then
      abort "Not a valid directory '${REPO}'."
    else
      if [ ! -d "${GIT_FOLDER}" ]; then
        abort "Not a valid git location '${GIT_FOLDER}'."
      else
        if [ ! -f "${GIT_FETCH_HEAD}" -o -n "$(find "${GIT_FETCH_HEAD}" -mtime +7 2>/dev/null)" ]; then
          information "Updating '${REPO}'."
          cd ${REPO} && git pull -q &>/dev/null &
        fi
      fi
    fi
  fi
}
function setupPrompt {
  local COLOR="xx"

  if [ "grey" == "${1}" ]; then
    COLOR="30"
  elif [ "red" == "${1}" ]; then
    COLOR="31"
  elif [ "green" == "${1}" ]; then
    COLOR="32"
  elif [ "yellow" == "${1}" ]; then
    COLOR="33"
  elif [ "blue" == "${1}" ]; then
    COLOR="34"
  elif [ "purple" == "${1}" ]; then
    COLOR="35"
  elif [ "teal" == "${1}" ]; then
    COLOR="36"
  elif [ "white" == "${1}" ]; then
    COLOR="37"
  else
    abort "Color not recognized '${1}'."
  fi

  if [ "$TERM" = "linux" ]; then
    export PS1="\[\e[32;1m\]\u@\H > \[\e[0m\]"
  else
    export PWD_PROMPT_CMD='tmp=${PWD%/*/*/*}; if [ ${#tmp} -gt 0 -a "$tmp" != "$PWD" ]; then myPWD=../${PWD:${#tmp}+1}; else myPWD=$PWD; fi'
    export USER_PROMPT_CMD='if [ ${#USER_IN_PROMPT} -gt 0 ]; then myUSER="[${USER}]@"; else myUSER=""; fi'
    export PROMPT_COMMAND="${PWD_PROMPT_CMD};${USER_PROMPT_CMD}"

    export PS1="\[\e]2;\u@\H \$PWD\a\e[01;${COLOR}m\]\$myUSER[\$myPWD]\$\[\e[0m\] "
  fi
}
function installRvmAndRubies() {
  if [[ ! -s "$HOME/.rvm/scripts/rvm" ]]; then
    logArgs "Getting rvm..."
    curl -sSL https://get.rvm.io | bash -s stable || return $?

    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
  fi

  while [ $# -gt 0 ]; do
    is_installed="$(rvm list | grep ${1})"

    if [ -z "${is_installed}" ]; then
      rvm install ${1}
    fi

    shift
  done

  logCmnd gem install bundler
}
function installBrewList() {
  local _CASK_LIST=(
    gimp
    gnucash
    macvim
    firefox
    thunderbird
    google-chrome
    vox
    mark-text
  )
  local _LIST=(
    coreutils
    gpg
    s3cmd
  )

  command -v brew >/dev/null 2>&1

  if [ "0" -eq "$?" ]; then
    for CASK_ITEM in "${_CASK_LIST[@]}"; do
      brew cask list ${CASK_ITEM} >/dev/null 2>&1

      if [ "1" -eq "$?" ]; then
        logCmnd brew cask install ${CASK_ITEM} || return $?
      else
        information "${CASK_ITEM} already installed."
      fi
    done

    for ITEM in "${_LIST[@]}"; do
      brew list ${ITEM} >/dev/null 2>&1

      if [ "1" -eq "$?" ]; then
        logCmnd brew install ${ITEM} || return $?
      else
        information "${ITEM} already installed."
      fi
    done
  else
    abort "brew command not installed"
  fi
}
function packagesFromList() {
  while [ $# -gt 0 ]; do
    sudo apt-get -yqq install "${1}"
    shift
  done
}
function sourceFromList() {
  while [ $# -gt 0 ]; do
    if [ -s "${1}" ]; then
      source ${1}
    fi
    shift
  done
}
function addToPathFromList() {
  while [ $# -gt 0 ]; do
    if [ -s "${1}" ]; then
      export PATH="${1}:${PATH}"
    fi
    shift
  done
}
function backupFromList() {
  local DIR=""

  if [[ "-d" == "${1}" ]]; then
    DIR="${HOME}/bash.backup/"

    if [ ! -d "${DIR}" ]; then
      logCmnd mkdir "${DIR}"
    fi
    shift
  fi

  while [ $# -gt 0 ]; do
    local FILE="${1}"
    local FULL_FILE="${FILE}"

    if [ ! -f "${FULL_FILE}" ]; then
      FULL_FILE="${HOME}/${FILE}"
    fi

    local FULL_BACKUP="${FILE##\.}.backup"

    if [ -e "${FULL_FILE}" ]; then
      if [ -L "${FULL_FILE}" ]; then
        logCmnd rm "${FULL_FILE}"
      else
        logCmnd mv "${FULL_FILE}" "${FULL_BACKUP}"

        if [ -n "${DIR}" ]; then
          logCmnd mv "${FULL_BACKUP}" "${DIR}"
        fi
      fi
    fi
    shift
  done
}
function softLinkFromList() {
  while [ $# -gt 0 ]; do
    local _FILES=(${1//:/ })
    local _LN_SOURCE="${_FILES[0]}"
    local _LN_TARGET="${_FILES[1]}"

    if [ -z "${_LN_SOURCE}" ]; then
      abort "No value passed for ln source '${1}'."
    fi

    if [ -z "${_LN_TARGET}" ]; then
      abort "No value passed for ln target '${1}'."
    fi

    if [ ! -s "${_LN_TARGET}" ]; then
      if [ -s "${_LN_SOURCE}" ]; then
        ln -s ${_LN_SOURCE} ${_LN_TARGET}
      fi
    fi
    shift
  done
}
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
    STRIPPED_STRING="$(echo "${STRIPPED_STRING}" | sed -e 's/[ ,''://&-]/_/g')"
    echo "${STRIPPED_STRING}"
  fi
}

function renameSafe() {
  while [ $# -gt 0 ]; do
    if [ -f "${1}" ]; then
      local FILENAME="${1##*/}"
      local DIRECTORY="${1%/*}"
      local EXTENSION="${FILENAME##*.}"
      local NEWFILE="$(removeUnwantedCharacters "${FILENAME%.*}").${EXTENSION}"

      if [ ! -d "${DIRECTORY}" ]; then
        DIRECTORY="."
      fi

      logCmnd mv "${1}" "${DIRECTORY}/${NEWFILE}"
    else
      warning "Not a file '${1}'."
    fi

    shift
  done
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

function git-rm-merged-local-branches {
  git branch --merged | grep "^\s*[_]" | xargs -n 1 git branch -d
}

function git-handle-pr-merged {
  local SCRIPT="${FUNCNAME[0]}"
  local BRANCH="master"
  local IS_BRANCH="no"

  if [ -n "${1}" ]; then
    BRANCH="${1}"
  fi

  logCmnd git checkout ${BRANCH} || return $?
  logCmnd git-resync-main-repo ${BRANCH} || return $?
  logCmnd git-rm-merged-local-branches || return $?
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

    if [ ! -d "${DIRECTORY}" ]; then
      DIRECTORY="${PWD}"
    fi

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
    logCmnd mp3info -n "" -l "" -y "" -a "${ARTIST}" -c "" -t "${TRACK_TITLE}" "${NEW_FILE}"
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
function git-smash {
  logCmnd git rebase -i HEAD~${1:-2}
}
function isMac {
  local _UNAME="$(uname -s)"

  if [[ ${_UNAME} = *"Darwin"* ]]; then
    echo "TRUE"
  else
    echo ""
  fi
}
function mikeplayer() {
  local SCRIPT="${FUNCNAME[0]}"
  export _PLAYLIST_=()
  local _PLAYLIST_FILE="${HOME}/.mikeplayer"
  local _DIRECTORY="/Users/mcrockett/DreamObjects/Music/"
  local _VOLUME="0.001"
  local _SHUFFLE=""
  local _USAGE_MSG=' [-n -s -v <level> -d <music directory> <songs>]
    Simple command line song player.

    Searches for music by name and adds to playlist, uses sox play to play songs.
    If the song is a file it is added to playlist, if not a file then we search for matching songnames and add all of them.

    -n Creates a new playlist (default is prepend to current playlist)
    -s Shuffle on
    -d <directory> Directory to search for music in.
    -v <level> Volume level on Mac, default is 0.001
       <songs> List of files or songnames to search for, if empty defaults to previous playlist.'

  command -v play >/dev/null 2>&1

  if [ "0" -eq "$?" ]; then
    for (( OPTIND=0; OPTIND <= ${#@}; ++i )); do
      while getopts "snv:d:" option; do
        case "${option}" in
          n)
            rm $_PLAYLIST_FILE
            ;;
          d)
            _DIRECTORY="${OPTARG}"
            ;;
          v)
            _VOLUME="${OPTARG}"
            ;;
          s)
            _SHUFFLE="TRUE"
            ;;
          *)
            abort "Invalid option '${OPTARG}'."
            usage "${_USAGE_MSG}"
            _USAGE_MSG=""
            ;;
        esac
      done

      OPTIND=$((OPTIND+1))
    done

    if [ ! -d "${_DIRECTORY}" ]; then
      abort "Directory not valid. '${_DIRECTORY}'."
      usage "${_USAGE_MSG}"
      _USAGE_MSG=""
    fi

    if [ -n "${_USAGE_MSG}" ]; then
      if [ -n "$(isMac)" ]; then
        osascript -e "set Volume ${_VOLUME}"
      fi

      for SONG in "${@}"; do
        if [ ! -f "${SONG}" ]; then
          FIND_SONGS="$(find ${_DIRECTORY} -type f -iname "*${SONG}*.mp3")"

          for FIND_SONG in "${FIND_SONGS}"; do
            if [ -f "${FIND_SONG}" ]; then
              echo "Found '${FIND_SONG}'."
              _PLAYLIST_+=(${FIND_SONG})
            fi
          done
        else
          echo "Adding '${SONG}'."
          _PLAYLIST_+=(${SONG})
        fi
      done

      _mikePlayListFromFile "APPEND"

      for SONG in "${_PLAYLIST_[@]}"; do
        printf "%s\n" "${_PLAYLIST_[@]}" > "${_PLAYLIST_FILE}"
      done

      if [ -n "${_SHUFFLE}" ]; then
        command -v shuf >/dev/null 2>&1

        if [ "0" -eq "$?" ]; then
          local _SHUF_FILE="${_PLAYLIST_FILE}.shuf"
          shuf < "${_PLAYLIST_FILE}" > "${_SHUF_FILE}"

          if [ "0" -eq "$?" ]; then
            mv "${_SHUF_FILE}" "${_PLAYLIST_FILE}"
            _mikePlayListFromFile
          fi
        else
          info "Can't shuffle don't have the 'shuf' command installed."
        fi
      fi

      printf "%s\n" "${_PLAYLIST_[@]}"

      export _PLAYLIST_SIZE_="${#_PLAYLIST_[@]}"
      export _SONG_INDEX_=0

      _mikeplay
    fi
  else
    abort "play command not installed, install sox"
  fi
}
function _mikePlayListFromFile {
  local _APPEND_="${1}"

  if [ -z "${_APPEND_}" ]; then
    _PLAYLIST_=()
  fi

  if [ -f $_PLAYLIST_FILE ]; then
    while read SONG; do
      if [ -f "${SONG}" ]; then
        _PLAYLIST_+=(${SONG})
      else
        echo "Invalid song in playlist '${SONG}'."
      fi
    done <"${_PLAYLIST_FILE}"
  fi
}
function _mikeplay {
  export _CURRENT_SONG_="${_PLAYLIST_[0]}"
  ((_SONG_INDEX_++))

  if [ -n "${_CURRENT_SONG_}" ]; then
    _PLAYLIST_=("${_PLAYLIST_[@]:1}")

    printf "Playing (${_SONG_INDEX_} / ${_PLAYLIST_SIZE_}): "
    (play "${_CURRENT_SONG_}" && clear && _mikeplay)
  fi
}
