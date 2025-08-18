#!/bin/bash

# Number of signals to test
NUM_GROUPS=16
# Signal num to start on
START_NUM=1
# ID
RUN_NAME="AutoLast"
OVERWRITE_LOGS=false   # Set to true to allow overwriting existing logs

mkdir -p logs
for i in $(seq $START_NUM $NUM_GROUPS); do
    # Tmux session and bespoke run for each signal
    SESSION="group_$i"
    LOGFILE="logs/${RUN_NAME}_$i.log"

    # Check if the tmux session already exists
    if tmux has-session -t $SESSION 2>/dev/null; then
        echo "Session $SESSION already exists — skipping."
        continue
    fi
    
    # Skip if log file exists and overwrite is disabled
    if [ -f "$LOGFILE" ] && [ "$OVERWRITE_LOGS" != true ]; then
        echo "Log file $LOGFILE already exists — skipping."
        continue
    fi

    tmux new-session -d -s $SESSION "GROUP_IDX=$i matlab -batch GBIS_BULK_Input_TmuxAuto -nodisplay -nosplash -nodesktop > $LOGFILE 2>&1; tmux kill-session -t $SESSION"
    echo "Started tmux session $SESSION with log $LOGFILE"
done

unset NUM_GROUPS
unset START_NUM
unset RUN_NAME
unset OVERWRITE_LOGS
