#!/bin/bash
# Usage: source scripts/checkSubmission.sh <submission, e.g V45_reL1wTT_170pre5> [task filter regex, e.g "4mu" or "200PU$"]
# Runs crab status for every task in parallel and prints the outputs in directory order.
# Tasks older than PURGE_DAYS are not queried: the scheduler has purged their job details by then anyway.

VERSION=$1
FILTER=${2:-.}
MAX_PARALLEL=8
PURGE_DAYS=40

if [[ -z $VERSION ]]; then
    echo "Error: missing submission - run with e.g source scripts/checkSubmission.sh V45_reL1wTT_170pre5"
    return 1
fi

BASE_DIR="ntuples/$VERSION"
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory $BASE_DIR does not exist!"
    return 1
fi

echo "Running crab status for subdirectories in $BASE_DIR..."

STATUSDIR=$(mktemp -d)
pids=()
for dir in "$BASE_DIR"/*/; do
    directory=$(basename "$dir")
    [[ $directory =~ $FILTER ]] || continue
    crabdir="$BASE_DIR/$directory/crab_$directory"
    out="$STATUSDIR/$directory.log"

    if [ ! -d "$crabdir" ]; then
        echo "Skipping $directory: crab_$directory not found" > "$out"
        continue
    fi

    # Task names start with the submission time (YYMMDD_HHMMSS), and crab.log records the task name
    submitted=$(grep -om1 '[0-9]\{6\}_[0-9]\{6\}:' "$crabdir/crab.log" 2>/dev/null)
    if [[ -n $submitted ]]; then
        age=$(( ( $(date +%s) - $(date -d "20${submitted:0:2}-${submitted:2:2}-${submitted:4:2}" +%s) ) / 86400 ))
        if [ $age -gt $PURGE_DAYS ]; then
            printf 'Processing: %s\nTask was submitted %s days ago.\nFiles are purged from Grid scheduler after %s days (crab status skipped)\n' \
                "$directory" "$age" "$PURGE_DAYS" > "$out"
            # keep the last server status crab recorded, so e.g. an old SUBMITREFUSED task is not hidden
            grep "Status on the CRAB server:" "$crabdir/crab.log" | tail -1 >> "$out"
            continue
        fi
    fi

    while [ $(jobs -pr | wc -l) -ge $MAX_PARALLEL ]; do sleep 1; done
    { echo "Processing: $directory"; crab status -d "$crabdir"; } > "$out" 2>&1 &
    pids+=($!)
done
[ ${#pids[@]} -gt 0 ] && wait "${pids[@]}"

cat "$STATUSDIR"/*.log 2>/dev/null
rm -r "$STATUSDIR"
echo "All directories processed."

# Helpful commands for checking on failed jobs
# crab getlog -d <path> --short # gets the stdout and stderr files to see what failures are - although I had some troubles here
# crab resubmit -d <path> [<options, e.g --maxmemory=X --maxjobruntime=Y>] # resubmits the failed jobs
