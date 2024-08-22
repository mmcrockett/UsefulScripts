#!/bin/bash

source "${HOME}/UsefulScripts.mmcrockett/LinuxSetup/bash.functions.sh"

DESKTOP="${HOME}/Desktop"
DATESTAMP="$(date "+%Y%m%d")"

OUT_LOG="/Users/mcrockett/launchctl.backupsh.err"
ERROR_LOG="/Users/mcrockett/launchctl.backupsh.out"

if [ -n "$(isMac)" ]; then
  RSYNC_FF_SRC="${HOME}/Library/Application Support/Firefox/Profiles/rajkkxt0.default"
else
  RSYNC_FF_SRC="${HOME}/.mozilla/firefox/rajkkxt0.default"
fi
RSYNC_FF_DEST="/home/washingrving/FirefoxProfile"

GNUCASH_LOCATION="${HOME}/DreamObjects/b137124-documents"
GNUCASH_BACKUP_LOCATION="/tmp/MikeAccounts.${DATESTAMP}.gnucash.xml"

function failfile {
  local FILE="${DESKTOP}/${1}-${DATESTAMP}.launchctl.failed.txt"

  touch "${FILE}"

  if [ -f "${ERROR_LOG}" ]; then
    cat "${ERROR_LOG}" >> "${FILE}"
  fi
}

function successfile {
  local FILE="${DESKTOP}/${DATESTAMP}.launchctl.success.txt"

  find ${DESKTOP} -name "*launchctl.success.txt" -mtime '+5' -exec rm -rf {} \;
  touch "${FILE}"

  if [ -f "${OUT_LOG}" ]; then
    cat "${OUT_LOG}" >> "${FILE}"
  fi
}

find ${GNUCASH_LOCATION} -name "*.log" -mtime '+10' -exec rm -rf {} \; || failfile "remove_gnucash_logs"
cp ${GNUCASH_LOCATION}/MikeAccounts.gnucash.xml ${GNUCASH_BACKUP_LOCATION} || failfile "gnucash_backup"
dhbackup || failfile "dreamobjects_sync"
rsync -az -e "ssh -i ${HOME}/.ssh/mmcrockett.rsa" "${RSYNC_FF_SRC}" washingrving@mmcrockett.com:${RSYNC_FF_DEST} || failfile "rsync_firefox"
successfile
