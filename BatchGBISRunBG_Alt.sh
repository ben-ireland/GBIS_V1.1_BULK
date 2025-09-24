#!/bin/bash
# Alternative bash-only script to BatchGBISRunBG.sh (no GNU Parallel needed)

# Number of signals to test
NUM_GROUPS=13
START_NUM=1
RUN_NAME="FullTest_McTGYangCDM"
OVERWRITE_LOGS=true
MAX_JOBS=16
SLEEP_BETWEEN=2

mkdir -p logs pids
JOB_LIST=$(seq $START_NUM $NUM_GROUPS)

# Remove logs if overwrite enabled
if [ "$OVERWRITE_LOGS" = true ]; then
    for i in $JOB_LIST; do
        rm -f "logs/${RUN_NAME}_$i.log"
    done
fi

if ! command -v matlab >/dev/null 2>&1; then
    echo "ERROR: MATLAB not found in PATH. Please load your MATLAB module or add it to PATH."
    exit 1
fi

# Background job launcher function
launch_jobs() {
    running=0
    for i in $JOB_LIST; do
        # Skip if already running or log exists (and overwrite off)
        if pgrep -af "matlab.*RUN_NAME=$RUN_NAME.*GROUP_IDX=$i" >/dev/null; then
            echo "Job $i already running — skipping."
            continue
        elif [ -f "logs/${RUN_NAME}_$i.log" ] && [ "$OVERWRITE_LOGS" != true ]; then
            echo "Log logs/${RUN_NAME}_$i.log exists and overwrite disabled — skipping."
            continue
        fi

        (
            export RUN_NAME="$RUN_NAME"
            export GROUP_IDX="$i"
            matlab -batch "GBIS_BULK_Input_TmuxAuto2" \
                -nodisplay -nosplash -nodesktop \
                > "logs/${RUN_NAME}_$i.log" 2>&1
        ) &

        echo "Started job $i (PID=$!)"
        echo $! >> "pids/${RUN_NAME}.pids"

        running=$((running+1))

        # Concurrency control
        if [ $running -ge $MAX_JOBS ]; then
            wait -n
            running=$((running-1))
        fi

        sleep $SLEEP_BETWEEN
    done

    # Wait for the last jobs to finish before subshell exits
    wait
    echo "All jobs finished."
}

MASTER_LOG="logs/${RUN_NAME}_master.log"
PID_FILE="pids/${RUN_NAME}.pids"
rm -f "$PID_FILE"

# Run the launcher in the background, detached with nohup
export RUN_NAME JOB_LIST MAX_JOBS SLEEP_BETWEEN OVERWRITE_LOGS
nohup bash -c "$(declare -f launch_jobs); launch_jobs" > "$MASTER_LOG" 2>&1 &
MASTER_PID=$!
echo $MASTER_PID >> "$PID_FILE"
disown

echo "Submitted jobs in background."
echo " Number of jobs: $NUM_GROUPS"
echo " Number of batches needed: "
echo "scale=0; ($NUM_GROUPS+($MAX_JOBS-1))/$MAX_JOBS" | bc -l
echo " Master log: $MASTER_LOG"
echo " Job logs:   logs/${RUN_NAME}_<idx>.log"
echo " PIDs file:  $PID_FILE"