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
function weeklyUpdate {
  local CUR_DIR="${PWD}"
  local REPO="${1}"
  local CMD_TO_RUN="${2}"
  local GIT_FOLDER="${REPO}/.git"
  local GIT_FETCH_HEAD="${GIT_FOLDER}/FETCH_HEAD"

  if [ ! -d "${REPO}" ]; then
    abort "Not a valid directory '${REPO}'."
  else
    if [ ! -d "${GIT_FOLDER}" ]; then
      abort "Not a valid git location '${GIT_FOLDER}'."
    else
      if [ ! -f "${GIT_FETCH_HEAD}" -o -n "$(find "${GIT_FETCH_HEAD}" -mtime +7 2>/dev/null)" ]; then
        information "Updating '${REPO}'."
        logCmnd "${CMD_TO_RUN}"
        logCmnd "touch ${GIT_FETCH_HEAD}"
      fi
    fi
  fi
}
function updateScripts {
  local HERE="${PWD}"
  logCmnd cd ${LINUX_SETUP_DIR}/..
  logCmnd git pull -q &>/dev/null
  logCmnd cd ${HERE}
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
function gvim-single {
  if [ "0" -eq "$#" ]; then
    gvim
  else
    ${GVIM_NO_OPTS} --servername singlejunkyfunkymonkey --remote-silent ${@}
  fi
}
function gvim-tmp-rb {
  local TMPFILE="$(mktemp ~/tmp/XXXXXX.gvim.rb)"
  ${GVIM_NO_OPTS} --servername tmp --remote-silent "${TMPFILE}"
}
function gvim-tmp-json {
  local TMPFILE="$(mktemp ~/tmp/XXXXXX.gvim.json)"
  ${GVIM_NO_OPTS} --servername tmp --remote-silent "${TMPFILE}"
}
function gvim-tmp-js {
  local TMPFILE="$(mktemp ~/tmp/XXXXXX.gvim.js)"
  ${GVIM_NO_OPTS} --servername tmp --remote-silent "${TMPFILE}"
}
function gvim {
  if [ "0" -eq "$#" ]; then
    local TMPFILE="$(mktemp ~/tmp/XXXXXX.gvim.txt)"
    ${GVIM_NO_OPTS} --servername tmp --remote-silent "${TMPFILE}"
  else
    echo "${@}"
    ${GVIM_NO_OPTS} --servername "$(basename ${PWD})" --remote-silent "${@}"
  fi
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
  local RESIZEDIR="${DIRECTORY}/resized"

  if [ -z "${MAXSIZE}" ]; then
    MAXSIZE=800;
  fi

  directoryExists "${DIRECTORY}" || return 1

  logCmnd mkdir -p ${RESIZEDIR}

  if [ -n "$(isMac)" ]; then
    logCmnd rename -f 's/\.JPG$/.jpg/' ${DIRECTORY}/*.JPG
  else
    logCmnd rename .JPG .jpg ${DIRECTORY}/*.JPG
  fi

  logCmnd cp ${DIRECTORY}/*.jpg ${RESIZEDIR}

  if [ -n "$(isMac)" ]; then
    logCmnd sips -Z $MAXSIZE ${RESIZEDIR}/*.jpg
  else
    for filename in ${RESIZEDIR}/*.jpg; do
      local FILENAMEONLY="${filename##*/}"
      local FILENAMENOEXT="${FILENAMEONLY%.jpg}"
      logCmnd magick "${filename}" -resize '480000@' "${RESIZEDIR}/${FILENAMENOEXT}.resized.jpg"
    done
  fi
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
function getCameraVolumes() {
  if [ -n "$(isMac)" ]; then
    local VOLUMES=("CANONEOS" "GECamera" "Picasa 3")
    local LOC="/Volumes/"
  else
    local VOLUMES=("5BA4-EC5B" "CAT")
    local LOC="/run/media/${USER}/"
  fi
  local FVOLUMES=""

  for VOLUME in "${VOLUMES[@]}"; do
    FVOLUMES="${FVOLUMES} ${LOC}/${VOLUME}"
  done

  echo "${FVOLUMES}"
}
function emptyCamera() {
  local SCRIPT="${FUNCNAME[0]}"
  local FULL_VOLUMES="$(getCameraVolumes)"

  for FULL_VOLUME in $FULL_VOLUMES; do
    local VOLUME_DIR="${FULL_VOLUME}/DCIM"
    local DATE_FORMAT="$(date "+%Y%m%d")"

    if [ -d "${FULL_VOLUME}" ]; then
      if [ -d "${VOLUME_DIR}" ]; then
        local NEW_DIRECTORY="${HOME}/Camera/${DATE_FORMAT}"

        if [ ! -d "${NEW_DIRECTORY}" ]; then
          logCmnd mkdir -p ${NEW_DIRECTORY}
        fi

        logCmnd find ${VOLUME_DIR} -iname "*.jpg" -exec mv {} ${NEW_DIRECTORY} \;
        logCmnd find ${VOLUME_DIR} -iname "*.mov" -exec mv {} ${NEW_DIRECTORY} \;
      else
        logArgs "Path on device not as expected '${VOLUME_DIR}'."
      fi

      if [ -n "$(isMac)" ]; then
        logCmnd diskutil eject "${FULL_VOLUME}"
      else
        logCmnd eject "${FULL_VOLUME}"
      fi
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
  local _DIRECTORY=""
  local _USAGE_MSG=' [-n <fileglob> -g <grep arguments> <directory>] <grepword> Calls find with grep options.
    -n <fileglob> Is passed to -name option, if missing causes -type f
    -g <grepargs> Defaults to -IH.
       <directory> Defaults to PWD.'

  for (( OPTIND=0; OPTIND <= ${#@}; OPTIND )); do
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

      if [ -z "${_DIRECTORY}" ] && [ -d "${_NOOPTARG}" ]; then
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
    _DIRECTORY="${PWD}"
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
function isMac {
  local _UNAME="$(uname -s)"

  if [[ ${_UNAME} = *"Darwin"* ]]; then
    echo "TRUE"
  else
    echo ""
  fi
}
function mikeplayer() {
  local _DIRECTORY="${HOME}/DreamObjects/b137124-music/"
  local _VOLUME=0.5
  ruby MikePlayer.rb --volume ${_VOLUME} --directory ${_DIRECTORY} ${@}
}
function processPhotos() {
  local _DIRECTORY="${HOME}/DreamObjects/b137124-pictures/"
  ruby ${SETUP_DIR}/PictureProcessor.rb --outdir ${_DIRECTORY} ${@} && dhbackup
}
function installPathogen() {
  local AUTOLOAD_PATH="${HOME}/.vim/autoload"
  local PATHOGEN_FILE="${AUTOLOAD_PATH}/pathogen.vim"

  if [ ! -s "${PATHOGEN_FILE}" ]; then
    mkdir -p ${AUTOLOAD_PATH} ~/.vim/bundle && curl -LSso ${PATHOGEN_FILE} https://tpo.pe/pathogen.vim
  fi
}
function installPlug() {
  local AUTOLOAD_PATH="${HOME}/.vim/autoload"
  local PLUG_FILE="${AUTOLOAD_PATH}/plug.vim"

  if [ ! -s "${PLUG_FILE}" ]; then
    mkdir -p ${AUTOLOAD_PATH} ~/.vim/bundle && curl -LSso ${PLUG_FILE} https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 
  fi
}
function rake-single {
 local TEST_FILE="$(echo ${1} | xargs)"

 logCmnd rake test TEST="${TEST_FILE}"
}
function s3cmd-dh {
  local CMD="${1}"
  local BUCKET="${2}"
  local PREFIX="b137124"

  if [ -z ${BUCKET} ]; then
    echo "Fail: requires name of the bucket"
    return 1
  fi

  if [ ${BUCKET##${PREFIX}} == ${BUCKET} ]; then
    BUCKET="${PREFIX}-${BUCKET}"
  fi

  local DIRECTORY="${HOME}/DreamObjects/${BUCKET}/"
  local REMOTE="s3://${BUCKET}/"
  local CMD_PARAMS=""

  if [[ get == ${CMD} ]]; then
    if [ ! -d "${DIRECTORY}" ]; then
      logCmnd mkdir -p "${DIRECTORY}"
    fi

    logCmnd s3cmd sync --skip-existing --cache /tmp/s3-${BUCKET}-cache ${REMOTE} ${DIRECTORY}
  elif [[ push == ${CMD} ]]; then
    if  [ ! -d "${DIRECTORY}" ]; then
      echo "Fail: Can't find directory '${DIRECTORY}'"
      return 1
    fi

    logCmnd s3cmd sync --no-delete-removed --no-preserve --exclude "*.log" --rexclude "^\." --rexclude "\/\." ${DIRECTORY} ${REMOTE}
  else
    echo "Fail: not a command '${CMD}'"
    return 1
  fi
}
function dhbackup {
  s3cmd-dh push 'b137124-music' || exit $?
  s3cmd-dh push 'b137124-documents' || exit $?
  s3cmd-dh push 'b137124-pictures' || exit $?
}
function rails-changed-tests {
  local CHANGED_FILES="$(git status -s | grep --invert "^D" | cut -c4- | grep ".*\.rb$")"
  local FILES_UNDER_TEST=""
  local RENAME="FALSE"

  for FILE in ${CHANGED_FILES}; do
    if [[ "->" == "${FILE}" ]] ; then
      RENAME="TRUE"
    else
      local TEST_FILE="${FILE}"

      if [[ "TRUE" == ${RENAME} ]]; then
        RENAME="FALSE"
        FILES_UNDER_TEST="${FILES_UNDER_TEST% *}"
      fi

      # If this isn't already a test file, follow rails convention and see if a testfile exists
      # EXAMPLE: app/models/person.rb
      # CHECK FOR: test/models/person_test.rb and add file
      if [ "${FILE%*_test.rb}" == "${FILE}" ]; then
        TEST_FILE="${FILE/app/test}"
        TEST_FILE="${TEST_FILE/.rb/_test.rb}"
      fi

      if [ -f "${TEST_FILE}" ]; then
        # If we didn't already include the file
        if [ "${FILES_UNDER_TEST%*${TEST_FILE}}" == "${FILES_UNDER_TEST}" ]; then
          FILES_UNDER_TEST="${FILES_UNDER_TEST} ${TEST_FILE}"
        fi
      fi
    fi
  done

  if [ -n "${FILES_UNDER_TEST}" ]; then
    logCmnd rails test ${FILES_UNDER_TEST} ${@}
  else
    echo "Didn't find any changes."
  fi
}
function rails-retry-test {
  local MAX=1000

  for n in $(seq 0 $MAX); do
    if [[ 0 == $(($n % 10)) && 0 != $n ]]; then printf '.'; fi
    rails test ${@} > /dev/null || break
  done;

  if [[ $n == $MAX ]]; then
    echo "Finished ${MAX} runs."
  else
    echo ""
  fi
}
yarn-changed-tests () 
{ 
    local CHANGED_FILES="$(git status -s | grep --invert "^D" | cut -c4- | grep ".*\.js\|jsx$")";
    local FILES_UNDER_TEST="";
    local RENAME="FALSE";
    for FILE in ${CHANGED_FILES};
    do
        if [[ "->" == "${FILE}" ]]; then
            RENAME="TRUE";
        else
            local TEST_FILE="${FILE}";
            if [[ "TRUE" == ${RENAME} ]]; then
                RENAME="FALSE";
                FILES_UNDER_TEST="${FILES_UNDER_TEST% *}";
            fi;
            if [ "${FILE%*.test.*}" == "${FILE}" ]; then
                TEST_FILE="${FILE/app/test}";
                TEST_FILE="${TEST_FILE/.js/.test.js}";
            fi;
            if [ -f "${TEST_FILE}" ]; then
                if [ "${FILES_UNDER_TEST%*${TEST_FILE}}" == "${FILES_UNDER_TEST}" ]; then
                    FILES_UNDER_TEST="${FILES_UNDER_TEST} ${TEST_FILE}";
                fi;
            fi;
        fi;
    done;
    if [ -n "${FILES_UNDER_TEST}" ]; then
        logCmnd yarn test ${FILES_UNDER_TEST} ${@};
    else
        echo "Didn't find any changes.";
    fi
}
function ps-find {
  local NAME="${1}"

  if [[ ${NAME} = *grep* ]]; then
    ps -A | grep "${NAME}"
  elif [ -n "${NAME}" ]; then
    ps -A | grep "${NAME}" | grep --invert 'grep'
  fi
}

[[ -s "${LINUX_SETUP_DIR}/git.functions.sh" ]] && source "${LINUX_SETUP_DIR}/git.functions.sh"
[[ -s "${LINUX_SETUP_DIR}/docker.functions.sh" ]] && source "${LINUX_SETUP_DIR}/docker.functions.sh"
