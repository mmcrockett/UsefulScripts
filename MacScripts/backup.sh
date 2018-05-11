#!/bin/bash

DESKTOP="${HOME}/Desktop"
DATESTAMP="$(date "+%Y%m%d")"

OUT_LOG="/Users/mcrockett/launchctl.backupsh.err"
ERROR_LOG="/Users/mcrockett/launchctl.backupsh.out"

RSYNC_SRC="${HOME}/Library/Application Support/Firefox/Profiles/rajkkxt0.default"
RSYNC_DEST="/home/washingrving/FirefoxProfile"

function failfile {
  local FILE="${DESKTOP}/${1}-${DATESTAMP}.launchctl.failed.txt"

  touch "${FILE}"

  if [ -f "${ERROR_LOG}" ]; then
    cat "${ERROR_LOG}" >> "${FILE}"
  fi
}

function successfile {
  local FILE="${DESKTOP}/${DATESTAMP}.launchctl.success.txt"

  find ${DESKTOP} -name "*launchctl.success.txt" -mtime 2 -exec rm -rf {} \;
  touch "${FILE}"

  if [ -f "${OUT_LOG}" ]; then
    cat "${OUT_LOG}" >> "${FILE}"
  fi
}

find ${HOME}/DreamObjects -name "*.log" -mtime 10 -exec rm -rf {} \; || failfile "remove_gnucash_logs"
s3cmd sync --exclude "*.log" --rexclude "^\." --rexclude "\/\." ${HOME}/DreamObjects/ s3://b137124-20150708-backups/ || failfile "dreamobjects_sync"
rsync -az -e "ssh -i ${HOME}/.ssh/mmcrockett.rsa" "${RSYNC_SRC}" washingrving@mmcrockett.com:${RSYNC_DEST} || failfile "rsync_firefox"
successfile
