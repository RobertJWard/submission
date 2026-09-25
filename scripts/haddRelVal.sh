# Usage: source haddRelVal.sh "<inputs>" [--timestamp]
#   default:     manifest mode - tracks exactly which files were included (safe against duplicates)
#   --timestamp: timestamp mode - includes any input file newer than the hadd output (best-effort,
#                may miss files delivered during the original hadd run)
# inputs is a set of space-separated inputs to hadd (e.g "170pre3 170pre2" though can also just be a sample)
# suggest to make a file 'ignore.haddRelVal.sh' bash source file which contains this command and which stores
# the history of your checks (via commented out inputs) that don't make sense to push to the repository

INPUTS=$1
USE_TIMESTAMP=false
[ "$2" = "--timestamp" ] && USE_TIMESTAMP=true
echo "Mode: $([ "$USE_TIMESTAMP" = true ] && echo 'timestamp' || echo 'manifest')"

if [[ -z $INPUTS ]]; then
    echo 'Error: missing input sample list - run with e.g source scripts/hadd.sh "<inputs>"'
    return
fi

REVISION=$(date +%y%m%d-%H%M)

TEMP=$(mktemp -d)
echo "Temp directory is $TEMP"

MAX_JOBS=12
# Manifest mode leaves files modified in the last MIN_AGE minutes for the next run, as they may still be mid-transfer
# (not applied in timestamp mode: a deferred file would end up older than the hadd output and never be picked up)
MIN_AGE=5
AGE_CUT="-mmin +$MIN_AGE"
[ "$USE_TIMESTAMP" = true ] && AGE_CUT=""
PARENTDIR="/eos/cms/store/group/dpg_trigger/comm_trigger/L1Trigger/roward/phase2/menu/ntuples/RelVal"

haddFiles() {
    local sample="$1"
    local temp=${sample#*v45/}
    local sampleShort=${temp%%_14*}
    # local sampleShort=${temp} #%%_TuneCP5*}
    # local sampleShort=${temp%%_TuneCP5*}
    local tempPU=${sample#*RelVal_}
    local samplePU=${tempPU%%_V45*}
    echo -e "Sample: $sampleShort\nPU: $samplePU\nDirectory: $sample" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
    local hadddir=${sample%/0000}/hadd
    local haddfile=$hadddir/output_Phase2_L1T.root
    local manifest=$hadddir/hadd_inputs.txt

    # echo "Haddfile will be: $haddfile"
    # echo "Hadd strings are: $INPUT $sampleShort $samplePU" 

    if [ -d $hadddir ]; then
        local new_files=()
        if [ "$USE_TIMESTAMP" = true ]; then
            mapfile -t new_files < <(find "$sample" -name "output_*.root" -newer "$haddfile")
        else
            for f in $(find "$sample" -name "output_*.root" $AGE_CUT); do
                grep -qxF "$f" "$manifest" 2>/dev/null || new_files+=("$f")
            done
        fi

        if [ ${#new_files[@]} -eq 0 ]; then
            echo "Up to date, skipping: $sampleShort $samplePU" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
        else
            echo "Appending ${#new_files[@]} new file(s) to $sampleShort $samplePU" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
            { time hadd -k -a -d $TEMP $haddfile "${new_files[@]}"; } >> logs/hadd_${INPUT}_${REVISION}.log
            # Update manifest regardless of mode so it stays in sync
            printf '%s\n' "${new_files[@]}" >> "$manifest"
            echo "Append complete: $INPUT $sampleShort $samplePU" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
        fi
    else
        local all_files=($(find "$sample" -name "output_*.root" $AGE_CUT))
        [ ${#all_files[@]} -eq 0 ] && { echo "No eligible input files yet, skipping: $sampleShort $samplePU" |& tee -a logs/hadd_${INPUT}_${REVISION}.log; return; }
        mkdir $hadddir
	# { time hadd -n 5 -j 12 -d $TEMP $TEMP/output_Phase2_L1T.root $sample/output_*.root; } |& tee -a logs/hadd_${INPUT}_${REVISION}.log
        { time hadd -fk -d $TEMP $TEMP/output_Phase2_L1T_${INPUT}_${sampleShort}_${samplePU}.root "${all_files[@]}"; } >> logs/hadd_${INPUT}_${REVISION}.log
        mv $TEMP/output_Phase2_L1T_${INPUT}_${sampleShort}_${samplePU}.root $haddfile
        printf '%s\n' "${all_files[@]}" > "$manifest"
        echo "Hadd complete: $INPUT $sampleShort $samplePU" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
        echo "Hadd output: $hadddir" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
    fi
}

for INPUT in $INPUTS; do
    echo "INPUT: $INPUT" |& tee logs/hadd_${INPUT}_${REVISION}.log
    for sample in $(find "$PARENTDIR/$INPUT/v45/" -wholename "*/0000" ! -wholename "*LongLived*"); do
	echo "Will hadd $sample"
        while [ $(jobs -p | wc -l) -ge $MAX_JOBS ]; do
            sleep 3
        done
        haddFiles "$sample" &
    done
done

wait
