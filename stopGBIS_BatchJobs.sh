#!/bin/bash
# Kills all MATLAB jobs started with GROUP_IDX (from BatchGBISRunBG.sh)
echo "Stopping all running MATLAB batch jobs..."
pkill -f "matlab.*GROUP_IDX="

# Check if tmux is running group versions and kill (from BatchGBISRun.sh)
echo "Stopping tmux sessions starting with 'group'..."
for s in $(tmux list-sessions -F "#S" 2>/dev/null | grep '^group'); do
    tmux kill-session -t "$s"
    echo "Killed tmux session: $s"
done

echo "All batch GBIS jobs and associated tmux sessions stopped."
