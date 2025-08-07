#!/bin/bash

# Number of signals to test
NUM_GROUPS=16
# Signal num to start on
START_NUM=1
# ID
RUN_NAME="AutoLast"

mkdir -p logs
for i in $(seq $START_NUM $NUM_GROUPS); do
    # Tmux session and bespoke run for each signal
    SESSION="group_$i"
    LOGFILE="logs/${RUN_NAME}_$i.log"
    tmux new-session -d -s $SESSION "GROUP_IDX=$i matlab -batch GBIS_BULK_Input_TmuxAuto -nodisplay -nosplash -nodesktop > $LOGFILE 2>&1; tmux kill-session -t $SESSION"
    echo "Started tmux session $SESSION with log $LOGFILE"
done
