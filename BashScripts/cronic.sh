#!/bin/bash

# Cronic v3 - cron job report wrapper
# Copyright 2007-2016 Chuck Houpt. No rights reserved, whatsoever.
# Public Domain CC0: http://creativecommons.org/publicdomain/zero/1.0/

set -eu

TMP=$(mktemp -d)
OUT=$TMP/cronic.out
ERR=$TMP/cronic.err
TRACE=$TMP/cronic.trace
MSG=$TMP/cronic.msg
FORCE=${CRONIC_FORCE:-}
MAILRECIPIENT=${MAILTO:-}

set +e
"$@" >$OUT 2>$TRACE
RESULT=$?
set -e

PATTERN="^${PS4:0:1}\\+${PS4:1}"
if grep -aq "$PATTERN" $TRACE; then
  ! grep -av "$PATTERN" $TRACE > $ERR
else
  ERR=$TRACE
fi

if [ $RESULT -ne 0 -o -s "$ERR" -o -n "${FORCE}" ]; then
  if [ $RESULT -ne 0 -o -s "$ERR" ]; then
    echo "Cronic detected failure or error output for the command:" >> "${MSG}"
  else
    echo "Cronic force for the command:" >> "${MSG}"
  fi

  echo "$@" >> "${MSG}"
  echo "RESULT CODE: $RESULT" >> "${MSG}"
  echo "" >> "${MSG}"
  echo "ERROR OUTPUT:" >> "${MSG}"
  cat "$ERR" >> "${MSG}"
  echo ""  >> "${MSG}"
  echo "STANDARD OUTPUT:" >> "${MSG}"
  cat "$OUT" >> "${MSG}"
  if [ $TRACE != $ERR ]; then
    echo ""  >> "${MSG}"
    echo "TRACE-ERROR OUTPUT:" >> "${MSG}"
    cat "$TRACE" >> "${MSG}"
  fi

  if [[ -n "$(command -v mail)" ]] && [[ -n "${MAILRECIPIENT}" ]]; then
    CMD_MSG="Undetectable Command"
    for POSSIBLE_CMD in $@; do
      if [ -n "$(command -v ${POSSIBLE_CMD})" ]; then
        CMD_MSG="${POSSIBLE_CMD}"
      fi
    done

    if [ -n "$(mail --version 2>/dev/null | grep GNU)" ]; then
      cat "${MSG}" | mail -s "Cron ${HOSTNAME} ${CMD_MSG}" -r "Cron" $MAILTO 
    else
      cat "${MSG}" | mail -s "Cron ${HOSTNAME} ${CMD_MSG}" $MAILTO 
    fi
  else
    cat "${MSG}"
  fi
fi

rm -rf "$TMP"
