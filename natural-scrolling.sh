#!/bin/sh
#
# Enables natural scrolling (requires using libinput, instead of evdev).
# Required GNU grep

pointers=$(xinput list | grep -i 'touch' | grep -Po 'id=([0-9])+.*pointer' | grep -Po '\d+')
# echo "Detected pointers: $pointers" | tr '\n' ' '
# echo ""

for pointer in $pointers; do
  xinput set-prop $pointer 'libinput Natural Scrolling Enabled' 1 2> /dev/null
  if [ $? == 0 ]; then
    echo "Enabled for $(xinput list --name-only $pointer)"
  fi
done
