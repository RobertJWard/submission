# INPUT=$1
# INPUTS="151X_preHCAL 151X_postHCAL"
# INPUTS="151X_noHCALStep 151X_rerunHCALStep 151X_newHCALStep 151pre4_P2GT"
# INPUTS="151X_noHCALStep_retry 151X_rerunHCALStep_retry 151X_newHCALStep_retry"
# INPUTS="151pre4_P2GT_retry 151pre4_P2GTupdate1"
# INPUTS="151pre4_P2GTupdate4"
# INPUTS="151pre4_retry"
# INPUTS="151pre4_VBF 160pre1_VBF"
INPUTS="170pre1"

REVISION="260514"

TEMP=$(mktemp -d)
echo "Temp directory is $TEMP"

MAX_JOBS=12
PARENTDIR="/eos/cms/store/group/dpg_trigger/comm_trigger/L1Trigger/roward/phase2/menu/ntuples/Spring24"

for INPUT in $INPUTS; do
    echo "INPUT: $INPUT" |& tee logs/hadd_${INPUT}_${REVISION}.log
    for sample in $(find "$PARENTDIR/$INPUT/v45/" -wholename "*_TuneCP5*/0000" ! -wholename "*LongLived*"); do
	while [ $(jobs -p | wc -l) -ge $MAX_JOBS ]; do
	    sleep 3
	done
	(
	    temp=${sample#*v45/}  # Remove everything up to and including "v45/"
	    sampleShort=${temp%%_TuneCP5*}  # Remove "_TuneCP5" and everything after
	    tempPU=${sample#*Spring24_} # Remove everything up to and including "Spring24_"
	    samplePU=${tempPU%%_V45*} # Remove "_V45" and everything after
	    echo -e "Sample: $sampleShort\nPU: $samplePU\nDirectory: $sample" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
	    hadddir=${sample/0000/hadd}
	    if [ -d $hadddir ]; then
		echo -e "Skipping as hadd directory already exists - check if this is expected\nHadddir: $hadddir"  |& tee -a logs/hadd_${INPUT}_${REVISION}.log
	    else
		mkdir $hadddir
		# { time hadd -n 5 -j 12 -d $TEMP $TEMP/output_Phase2_L1T.root $sample/output_*.root; } |& tee -a logs/hadd_${INPUT}_${REVISION}.log
		{ time hadd -fk -d $TEMP $TEMP/output_Phase2_L1T_${INPUT}_${sampleShort}_${samplePU}.root $sample/output_*.root; } >> logs/hadd_${INPUT}_${REVISION}.log
		mv $TEMP/output_Phase2_L1T_${INPUT}_${sampleShort}_${samplePU}.root $hadddir/output_Phase2_L1T.root
		echo "Hadd complete: $INPUT $sampleShort $samplePU"  |& tee -a logs/hadd_${INPUT}_${REVISION}.log
		echo "Hadd output: $hadddir"  |& tee -a logs/hadd_${INPUT}_${REVISION}.log
	    fi
	) &
    done
done

wait
