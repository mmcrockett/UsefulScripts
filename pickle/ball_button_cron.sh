#!/bin/sh
# Wraps a ball_button.rb cron job: applies the setlock, captures output to
# its usual log, and records a failed run in History on a non-zero exit -
# so crontab stays a one-line-per-job list instead of repeating
# this setlock/redirect/printf boilerplate on every line.
#
# Usage: ball_button_cron.sh {dryrun|schedule|reserve|reserve2}

DIR="$(cd "$(dirname "$0")" && pwd)"
BB="$DIR/ball_button.sh"

case "$1" in
  dryrun)
    LOCK=/tmp/cronlock.817513.396513
    LOG="$DIR/ball_button.dryrun.cron.log"
    SUBCOMMAND=""
    export D=90 RESERVE_START=7:30 DRY_RUN=true
    ;;
  schedule)
    LOCK=/tmp/cronlock.817513.396513
    LOG="$DIR/ball_button.cron.schedule.log"
    SUBCOMMAND="sync"
    ;;
  reserve)
    LOCK=/tmp/cronlock.817513.396513
    LOG="$DIR/ball_button.cron.log"
    SUBCOMMAND="reserve-today"
    ;;
  reserve2)
    LOCK=/tmp/cronlock.817513.396514
    LOG="$DIR/ball_button.cron.log"
    SUBCOMMAND="reserve-today"
    ;;
  *)
    echo "usage: $0 {dryrun|schedule|reserve|reserve2}" >&2
    exit 64
    ;;
esac

/usr/bin/setlock -n "$LOCK" "$BB" $SUBCOMMAND >> "$LOG" 2>&1
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  "$BB" record-failure "${1} ${SUBCOMMAND}" "$STATUS" >> "$LOG" 2>&1 || true
fi
