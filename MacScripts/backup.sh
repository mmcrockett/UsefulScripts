#!/bin/bash

DESKTOP="${HOME}/Desktop"
DATESTAMP="$(date "+%Y%m%d")"

RSYNC_SRC="${HOME}/Library/Application Support/Firefox/Profiles/rajkkxt0.default"
RSYNC_DEST="/home/washingrving/FirefoxProfile"

function failfile {
  touch "${DESKTOP}/${1}-${DATESTAMP}.launchctl.failed"
}

find ${HOME}/DreamObjects -name "*.log" -mtime 10 -exec rm -rf {} \; || failfile "remove_gnucash_logs"
s3cmd sync --exclude "*.log" --rexclude "^\." --rexclude "\/\." ${HOME}/DreamObjects/ s3://b137124-20150708-backups/ || failfile "dreamobjects_sync"
rsync -az -e "ssh -i ${HOME}/.ssh/mmcrockett.rsa" "${RSYNC_SRC}" washingrving@mmcrockett.com:${RSYNC_DEST} || failfile "rsync_firefox"
