#!/bin/bash

# Usage stopGBIS_BatchJobs.sh <PIDS_DIR>
# Directory containing a file Run_Name.pids with all the process IDs for GBIS-BULK runs

PIDS_DIR=$1
# Kills all MATLAB jobs started with GROUP_IDX (from BatchGBISRunBG_Alt.sh)
if [ ! -d "$PIDS_DIR" ]; then
    echo "No $PIDS_DIR directory found, nothing to stop."
    echo $PIDS_DIR
else
    for pidfile in "$PIDS_DIR"/*.pids; do
        [ -e "$pidfile" ] || continue  # skip if no .pids files
        echo "Processing $pidfile..."

        while read -r pid; do
            if [ -n "$pid" ]; then
                if kill -0 "$pid" 2>/dev/null; then
                    echo " Killing PID $pid"
                    kill "$pid"
                    sleep 5
                    kill -9 "$pid" 
                else
                    echo " PID $pid not running"
                fi
            fi
        done < "$pidfile"

        # rm -f "$pidfile"
        # echo "Removed $pidfile"
    done
    echo "All BatchGBISRunBG_Alt.sh jobs stopped."
fi

# Kills all MATLAB jobs started with GROUP_IDX (from BatchGBISRunBG.sh)
echo "Stopping all running MATLAB batch jobs..."
pkill -f "matlab.*GROUP_IDX="
echo "All BatchGBISRunBG.sh jobs stopped."

# Check if tmux is running group versions and kill (from BatchGBISRun.sh)
echo "Stopping tmux sessions starting with 'group'..."
for s in $(tmux list-sessions -F "#S" 2>/dev/null | grep '^group'); do
    tmux kill-session -t "$s"
    echo "Killed tmux session: $s"
done

echo "All batch GBIS jobs with associated tmux sessions stopped."
echo "All jobs stopped"