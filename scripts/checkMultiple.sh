# Usage: source scripts/checkMultiple.sh "<joblist>" [check|resubmit|kill|move|clear|unstick] [task filter regex]
#   joblist:  space-separated submissions to check (e.g "170pre3 170pre2" though can also just be a single one)
#   check:    (default) crab status for every task, then a one-line-per-task summary
#   resubmit: check, then crab resubmit only the tasks summarised as FAILED
#   kill:     check, then crab kill + move aside the crab_ dirs of the unfinished (RUNNING/PROBING/STUCK/SPLIT FAILED)
#             tasks, after you confirm, so they can be submitted fresh
#   move:     check, then move aside the crab_ dirs of already KILLED tasks, after you confirm, so they can be
#             submitted fresh
#   clear:    check, then move aside the crab_ dirs of SUBMITREFUSED tasks, after you confirm, so they can be submitted fresh
#   unstick:  check, then crab kill + move aside the crab_ dirs of STUCK / SPLIT FAILED tasks, after you confirm,
#             so they can be submitted fresh
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
    echo 'Error: missing a joblist - run with e.g source scripts/checkMultiple.sh "<joblist>" [check|resubmit|kill|clear|unstick] [filter]'
    return
fi
case $ACTION in
    check|resubmit|kill|move|clear|unstick) ;;
    *) echo "Error: unknown action '$ACTION' - use check, resubmit, kill, move, clear or unstick"; return 1 ;;
esac

echo "joblist: $joblist, action: $ACTION, filter: $FILTER"

# crab needs a CMSSW environment to run in (any release will do), so check cmsenv has been done first
if [[ -z $CMSSW_BASE ]]; then
    echo "Error: no CMSSW environment - run cmsenv inside a CMSSW release area first (any release works for crab)"
    return 1
fi

# The crab calls run in the background, where they can't ask for your grid passphrase, so make sure a proxy is valid first
# (including its CMS attribute, which -exists alone does not check)
if ! voms-proxy-info -exists -valid 1:00 -acexists cms &> /dev/null; then
    echo "No valid grid proxy (or less than 1h left, or no CMS attribute), creating one:"
    voms-proxy-init -voms cms -rfc -valid 192:00 || { echo "Error: could not create a grid proxy"; return 1; }
fi

# crab occasionally renews its own server-side credential, asking for your grid passphrase even when the local proxy
# is fine. Let one crab call do that here in the foreground, so the parallel ones later don't all try to ask at once.
# Use a task that was actually submitted (its crab.log has a task name), so a broken leftover crab_ dir can't block the run.
_first=""
for job in $joblist; do
    _first=$(grep -l '[0-9]\{6\}_[0-9]\{6\}:' ntuples/V45_reL1wTT_$job/*/crab_*/crab.log 2>/dev/null | head -1)
    [[ -n $_first ]] && { _first=$(dirname "$_first"); break; }
done
if [[ -n $_first ]]; then
    _crabtest=$(mktemp)
    _ok=false
    for _try in 1 2 3; do
        crab status -d "$_first" > "$_crabtest" 2>&1
        grep -q "Status on the CRAB server:" "$_crabtest" && { _ok=true; break; }
        echo "crab could not get a task status (wrong grid passphrase?) - attempt $_try of 3"
    done
    if ! $_ok; then
        echo "Error: crab status keeps failing, so not starting the parallel checks. Last lines from crab:"
        tail -5 "$_crabtest"
        rm -f "$_crabtest"
        return 1
    fi
    rm -f "$_crabtest"
fi

# Ask before doing something drastic: y/yes (any case) continues, n/no or anything else skips
_confirm() {
    local answer
    read -p "$1 [y/yes to continue, n/no to skip]: " answer
    [[ ${answer,,} == y || ${answer,,} == yes ]]
}

for job in $joblist; do
    sub=V45_reL1wTT_$job
    log=logs/check_${job}_${revision}.log
    echo "Checking $job (full crab status output in $log)"
    source scripts/checkSubmission.sh $sub "$FILTER" > $log 2>&1
    echo "Summary for $job:"
    source scripts/summariseCrabLog.sh $log
    # SPLIT FAILED tasks: fetch the probe logs and show why the probes failed
    source scripts/diagnoseProbes.sh $sub $log logs/probes_${job}_${revision}

    case $ACTION in
        resubmit) targets=$(source scripts/summariseCrabLog.sh --names FAILED $log) ;;
        kill)     targets=$(source scripts/summariseCrabLog.sh --names "RUNNING|PROBING|STUCK|SPLIT FAILED" $log) ;;
        move)     targets=$(source scripts/summariseCrabLog.sh --names KILLED $log) ;;
        clear)    targets=$(source scripts/summariseCrabLog.sh --names "SUBMITREFUSED|SUBMITFAILED" $log) ;;
        unstick)  targets=$(source scripts/summariseCrabLog.sh --names "STUCK|SPLIT FAILED" $log) ;;
        *)        continue ;;
    esac
    if [[ -z $targets ]]; then
        echo "Nothing to $ACTION for $job"
        continue
    fi
    if [[ $ACTION == unstick || $ACTION == kill || $ACTION == move ]]; then
        # kill the tasks (harmless if the scheduler already gave up; skipped for move, where they already are),
        # then move the crab_ project dir aside (keeping its crab.log) so the task can be submitted fresh
        if [[ $ACTION == move ]]; then
            echo "Will move aside the crab_ project dirs of (so they can be submitted fresh):"
        else
            echo "Will crab kill${CRAB_OPTS:+ $CRAB_OPTS}, then move aside the crab_ project dirs of (so they can be submitted fresh):"
        fi
        printf '  %s\n' $targets
        _confirm "${ACTION^} these?" || { echo "Not doing $ACTION for anything in $job"; continue; }
        for t in $targets; do
            crabdir=ntuples/$sub/$t/crab_$t
            stamp=$(grep -om1 '[0-9]\{6\}_[0-9]\{6\}:' $crabdir/crab.log 2>/dev/null); stamp=${stamp%:}
            if [[ $ACTION != move ]]; then
                echo "crab kill: $t" |& tee -a logs/${ACTION}_${job}_${revision}.log
                crab kill $CRAB_OPTS -d $crabdir |& tee -a logs/${ACTION}_${job}_${revision}.log
            fi
            mv -v $crabdir ntuples/$sub/$t/old_crab_${t}_${revision} |& tee -a logs/${ACTION}_${job}_${revision}.log
            [[ -n $stamp ]] && echo "  old task timestamp: $stamp - if a .../$stamp/ output folder exists on EOS, move it aside before hadding" |& tee -a logs/${ACTION}_${job}_${revision}.log
        done
        echo "Now resubmit these with submit.py --create --submit"
        continue
    fi
    if [[ $ACTION == clear ]]; then
        # Refused/failed-to-submit tasks never ran, so only the local crab_ project dir blocks a fresh submit.
        # It is moved aside (not deleted) to keep its crab.log; nothing on EOS needs touching.
        echo "Will move aside the crab_ project dirs of (so they can be submitted fresh):"
        printf '  %s\n' $targets
        _confirm "Clear these?" || { echo "Not clearing anything for $job"; continue; }
        for t in $targets; do
            mv -v ntuples/$sub/$t/crab_$t ntuples/$sub/$t/old_crab_${t}_${revision} |& tee -a logs/clear_${job}_${revision}.log
        done
        echo "Now resubmit these with submit.py --create --submit (once the input is fully on disk)"
        continue
    fi
    echo "Will crab $ACTION${CRAB_OPTS:+ $CRAB_OPTS}:"
    printf '  %s\n' $targets
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
