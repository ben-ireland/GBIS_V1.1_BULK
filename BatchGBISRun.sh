#!/bin/bash

# Number of signals to test
NUM_GROUPS=3
RUN_NAME="AutoTest"

mkdir -p logs
for i in $(seq 1 $NUM_GROUPS); do
    # Tmux session and bespoke run for each signal
    SESSION="group_$i"
    LOGFILE="logs/${RUN_NAME}_group_$i.log"
    tmux new-session -d -s $SESSION "GROUP_IDX=$i matlab -batch GBIS_BULK_Input_TmuxAuto > $LOGFILE 2>&1"
    echo "Started tmux session $SESSION with log $LOGFILE"
done
