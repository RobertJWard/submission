# Note: run with e.g `source scripts/checkMultiple.sh "<joblist>" <resubmit>
# joblist is a set of space-separated submissions jobs to check (e.g "170pre3 170pre2" though can also just be a single job),
# and resubmit is TRUE or FALSE to try resubmitting failed jobs (FALSE by default)
# suggest to make a file 'ignore.checkMultiple.sh' bash source file which contains this command and which stores
# the history of your checks (via commented out joblists) that don't make sense to push to the repository 

revision=$(date +%y%m%d-%H%M)
joblist=$1
RESUBMIT=$2

if [[ -z $joblist ]]; then
    echo 'Error: missing a joblist - run with e.g source scripts/checkMultiple.sh "<joblist>"'
    return
fi

echo "joblist: $joblist"

for job in $joblist; do
    if [[ $RESUBMIT == "TRUE" ]]; then
	echo Resubmitting $job
	source scripts/resubmitSubmission.sh V45_reL1wTT_$job |& tee logs/resubmit_${job}_${revision}.log
    else
	echo Checking $job
	source scripts/checkSubmission.sh V45_reL1wTT_$job |& tee logs/check_${job}_${revision}.log
    fi
done

if [[ $RESUBMIT == "TRUE" ]]; then
    echo Done # do nothing
else
    for job in $joblist; do
	echo Summary for $job:
	grep -r "finished" logs/check_${job}_${revision}.log
	grep -r "   failed" logs/check_${job}_${revision}.log
	grep -r "running" logs/check_${job}_${revision}.log
	grep -r "transferring" logs/check_${job}_${revision}.log
	grep -r "rescheduled" logs/check_${job}_${revision}.log
	grep -r "idle" logs/check_${job}_${revision}.log
    done
fi

