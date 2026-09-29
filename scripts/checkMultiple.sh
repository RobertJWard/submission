# Usage: source scripts/checkMultiple.sh "<joblist>" [check|resubmit|kill|clear] [task filter regex]
#   joblist:  space-separated submissions to check (e.g "170pre3 170pre2" though can also just be a single one)
#   check:    (default) crab status for every task, then a one-line-per-task summary
#   resubmit: check, then crab resubmit only the tasks summarised as FAILED
#   kill:     check, then crab kill only the still-active (RUNNING/PROBING) tasks, after you confirm
#   clear:    check, then move aside the crab_ dirs of SUBMITREFUSED tasks, after you confirm, so they can be submitted fresh
#   filter:   optional regex on the task directory name, e.g "4mu" or "200PU$" (applies to all actions)
# Extra crab options for resubmit/kill can be passed via CRAB_OPTS, e.g
#   CRAB_OPTS="--maxmemory=6000" source scripts/checkMultiple.sh "170pre5" resubmit
# suggest to make a file 'ignore.checkMultiple.sh' bash source file which contains this command and which stores
# the history of your checks (via commented out joblists) that don't make sense to push to the repository

revision=$(date +%y%m%d-%H%M)
joblist=$1
ACTION=${2:-check}
FILTER=${3:-.}
[[ $ACTION == TRUE ]] && ACTION=resubmit   # old usage
[[ $ACTION == FALSE ]] && ACTION=check

if [[ -z $joblist ]]; then
    echo 'Error: missing a joblist - run with e.g source scripts/checkMultiple.sh "<joblist>" [check|resubmit|kill|clear] [filter]'
    return
fi
case $ACTION in
    check|resubmit|kill|clear) ;;
    *) echo "Error: unknown action '$ACTION' - use check, resubmit, kill or clear"; return 1 ;;
esac

echo "joblist: $joblist, action: $ACTION, filter: $FILTER"

for job in $joblist; do
    sub=V45_reL1wTT_$job
    log=logs/check_${job}_${revision}.log
    echo "Checking $job (full crab status output in $log)"
    source scripts/checkSubmission.sh $sub "$FILTER" > $log 2>&1
    echo "Summary for $job:"
    source scripts/summariseCrabLog.sh $log

    case $ACTION in
        resubmit) targets=$(source scripts/summariseCrabLog.sh --names FAILED $log) ;;
        kill)     targets=$(source scripts/summariseCrabLog.sh --names "RUNNING|PROBING" $log) ;;
        clear)    targets=$(source scripts/summariseCrabLog.sh --names "SUBMITREFUSED|SUBMITFAILED" $log) ;;
        *)        continue ;;
    esac
    if [[ -z $targets ]]; then
        echo "Nothing to $ACTION for $job"
        continue
    fi
    if [[ $ACTION == clear ]]; then
        # Refused/failed-to-submit tasks never ran, so only the local crab_ project dir blocks a fresh submit.
        # It is moved aside (not deleted) to keep its crab.log; nothing on EOS needs touching.
        echo "Will move aside the crab_ project dirs of (so they can be submitted fresh):"
        printf '  %s\n' $targets
        read -p "Type 'yes' to clear these: " answer
        [[ $answer == yes ]] || { echo "Not clearing anything for $job"; continue; }
        for t in $targets; do
            mv -v ntuples/$sub/$t/crab_$t ntuples/$sub/$t/old_crab_${t}_${revision} |& tee -a logs/clear_${job}_${revision}.log
        done
        echo "Now resubmit these with submit.py --create --submit (once the input is fully on disk)"
        continue
    fi
    echo "Will crab $ACTION${CRAB_OPTS:+ $CRAB_OPTS}:"
    printf '  %s\n' $targets
    if [[ $ACTION == kill ]]; then
        read -p "Type 'yes' to kill these: " answer
        [[ $answer == yes ]] || { echo "Not killing anything for $job"; continue; }
    fi
    for t in $targets; do
        echo "crab $ACTION: $t" |& tee -a logs/${ACTION}_${job}_${revision}.log
        crab $ACTION $CRAB_OPTS -d ntuples/$sub/$t/crab_$t |& tee -a logs/${ACTION}_${job}_${revision}.log
    done
done

# Old summary, kept for reference (replaced by scripts/summariseCrabLog.sh):
# if [[ $RESUBMIT == "TRUE" ]]; then
#     echo Done # do nothing
# else
#     for job in $joblist; do
# 	echo Summary for $job:
# 	grep -r "finished" logs/check_${job}_${revision}.log
# 	grep -r "   failed" logs/check_${job}_${revision}.log
# 	grep -r "running" logs/check_${job}_${revision}.log
# 	grep -r "transferring" logs/check_${job}_${revision}.log
# 	grep -r "rescheduled" logs/check_${job}_${revision}.log
# 	grep -r "idle" logs/check_${job}_${revision}.log
#     done
# fi
