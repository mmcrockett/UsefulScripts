while true; do
  for mousename in "cameron’s Mouse" "work mouse"; do
    MOUSEID=$(xinput | grep "${mousename}" | grep -o -E '[0-9]+' | head -n 1)

    if [ -n "${MOUSEID}" ]; then
      CSETTINGS="$(xinput get-button-map ${MOUSEID})"
      ESETTINGS="1 1 3 4 5 6 7 "

      if [[ "${ESETTINGS}" != "${CSETTINGS}" ]]; then
        xinput --set-button-map $MOUSEID $ESETTINGS
      fi
    fi
  done
  sleep 2
done &
