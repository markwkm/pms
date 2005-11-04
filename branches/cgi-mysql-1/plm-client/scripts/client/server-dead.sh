#!/bin/bash

PIDS=`ls /home/plm/scratch/*/PID 2> /dev/null`

if [ -z "$PIDS" ]; then
    exit 0
fi

RUNNING=`ps axw | grep -v grep | grep supervisor -c`

if [ $RUNNING == 0 ]; then
  echo "Error: No supervisor scripts running"
  for f in $PIDS; do
    if [ -f $f ]; then
      echo "  - Removing PID file: $f"
      rm -f $f
    else
      echo "  - PID [$f] has already been removed"
    fi
  done
fi
