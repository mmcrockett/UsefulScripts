#!/bin/sh
# Wraps a ball_button.rb cron job: applies the setlock, captures output to
# its usual log, and appends a JSON line to ball_button.errors.log on
# failure - so crontab stays a one-line-per-job list instead of repeating
# this setlock/redirect/printf boilerplate on every line.
#
# Usage: ball_button_cron.sh {dryrun|schedule|reserve|reserve2}

DIR="$(cd "$(dirname "$0")" && pwd)"
BB="$DIR/ball_button.sh"
ERRORS_LOG="$DIR/ball_button.errors.log"

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
    SUBCOMMAND="generate-schedule"
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
  printf '{"time":"%s","context":"cron","message":"%s failed (exit %s) - see %s"}\n' \
    "$(date -Iseconds)" "${1} ${SUBCOMMAND}" "$STATUS" "$(basename "$LOG")" \
    >> "$ERRORS_LOG"
fi
