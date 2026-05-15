# joblist="151X_D110 151X_D116 151X_D121 151pre3_only48136 151pre3_SC8Nano"
# joblist="151pre3_L1EGupdate1"
# joblist="151pre3_E2ENNVtx 151pre3_E2ENNVtxOff 151X_E2ENNVtx 151X_L1EGupdate2"
# joblist="151X_E2ENNVtx 151X_L1EGupdate2 151pre3_L1EGupdate3 151pre3_E2ENNVtxOnlyFind 151pre3_E2ENNVtxOnlyAssoc"
# joblist="151X_E2ENNVtx 151X_L1EGupdate2 151pre3 151pre3_E2ENNVtxOnlyFind 151pre3_E2ENNVtxOnlyAssoc"
# joblist="151pre3"
# joblist="151pre3_DispVtx 151pre1 151pre3_L1EGupdate4 151X_MergedAR24_FindOff 151X_MergedAR24_FindOn 151X_AllAR25_FindOff 151X_AllAR25_FindOn 151X_AllAR25_FindOnAssocOn 151X_AllAR25_FindOffAssocOn"
# joblist="151pre3_E2ENNVtxOnlyFind 151pre3_E2ENNVtxOnlyAssoc"
# joblist="151X_preHCAL 151X_postHCAL"
# joblist="151X_noHCALStep 151X_rerunHCALStep 151X_newHCALStep 151pre4_P2GT"
# joblist="151X_noHCALStep_retry 151X_rerunHCALStep_retry 151X_newHCALStep_retry 151pre4_P2GT_retry 151pre4_P2GTupdate1"
# joblist="151pre4_P2GT_retry 151pre4_P2GTupdate1"
# joblist="151pre4_P2GTupdate2"
# joblist="151pre4_P2GTupdate4"
# joblist="151pre4 160pre1 160pre2"
# joblist="151pre4_retry 160pre2_retry"
# joblist="160pre2_retry"
# joblist="151pre4_VBF 160pre1_VBF"
joblist="170pre1"

revision=9am
RESUBMIT=$1

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

