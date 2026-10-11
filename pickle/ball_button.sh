#!/bin/sh
# Invoked directly by cron (no symlink) so __dir__ inside ball_button.rb
# resolves to this directory - where users.json/schedule.json/errors.log
# actually live.
DIR="$(dirname "$0")"
exec /usr/bin/ruby "$DIR/ball_button.rb" "$@"
