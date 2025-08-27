#!/bin/bash

# Number of signals to test
NUM_GROUPS=16
START_NUM=1
RUN_NAME="AutoCDMsV3"
OVERWRITE_LOGS=true
MAX_JOBS=16
SLEEP_BETWEEN=2   # seconds between starting each job

mkdir -p logs
JOB_LIST=$(seq $START_NUM $NUM_GROUPS)

# Remove existing logs if overwrite is enabled
if [ "$OVERWRITE_LOGS" = true ]; then
    for i in $JOB_LIST; do
        rm -f "logs/${RUN_NAME}_$i.log"
    done
fi

# Function to check if a group job is already running
is_running() {
    local idx=$1
    pgrep -af "matlab.*GROUP_IDX=$idx" >/dev/null
}

# Filter out jobs that are already running
FILTERED_JOBS=()
for i in $JOB_LIST; do
    if is_running $i; then
        echo "Job for GROUP_IDX=$i already running — skipping."
    elif [ -f "logs/${RUN_NAME}_$i.log" ] && [ "$OVERWRITE_LOGS" != true ]; then
        echo "Log file logs/${RUN_NAME}_$i.log exists and overwrite disabled — skipping."
    else
        FILTERED_JOBS+=($i)
    fi
done

if [ ${#FILTERED_JOBS[@]} -eq 0 ]; then
    echo "No new jobs to submit."
    exit 0
fi

# Run jobs with GNU parallel + nohup
nohup parallel -j $MAX_JOBS \
    --delay $SLEEP_BETWEEN \
    --joblog logs/parallel_joblog.txt \
    'GROUP_IDX={} matlab -batch "GBIS_BULK_Input_TmuxAuto" -nodisplay -nosplash -nodesktop > logs/'"$RUN_NAME"'_{}.log 2>&1' \
    ::: "${FILTERED_JOBS[@]}" &

echo "Submitted ${#FILTERED_JOBS[@]} jobs with GNU parallel."
echo "Logs: logs/${RUN_NAME}_<idx>.log"
echo "Job tracking: logs/parallel_joblog.txt"
