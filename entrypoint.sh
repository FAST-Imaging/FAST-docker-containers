#!/bin/bash
if [ "$TYPE" = "python" ]; then
  # Activate python environment if this is a python image
  source environment/bin/activate
fi
if [ "$VIRTUALGL" = "false" ]; then
  if [ "$X_SERVER" = "xvfb" ]; then
    export DISPLAY=:0
    echo "Starting Xvfb at $DISPLAY .."
    Xvfb "$DISPLAY" -screen 0 1920x1080x24 &
    echo "Xvfb started"
  fi
  exec "$@"
else
  # VirtualGL image : We have to find an available DISPLAY number
  echo "Starting Xvfb at with VGL .."
  # Lock to avoid race conditions
  exec {lock_fd}>/var/lock/xlockfile || exit 1
  flock "$lock_fd" || { echo "ERROR: flock() failed." >&2; exit 1; }
  # Find available display number automatically
  DISPLAY_NUM=0
  until [[ $xvfb ]]; do
    if [[ -e /tmp/.X11-unix/X$DISPLAY_NUM ]]; then
      let DISPLAY_NUM=$DISPLAY_NUM+1
    else
      Xvfb :$DISPLAY_NUM -screen 0 1920x1080x24 &
      xvfb=$!
    fi
  done
  # Unlock
  flock -u "$lock_fd"
  # Set VGL_DISPLAY which tells vglrun where to do the rendering
  export VGL_DISPLAY=:$DISPLAY_NUM
  echo "Started Xvfb at $VGL_DISPLAY"
  # We have to run vglrun before command
  exec vglrun "$@"
fi