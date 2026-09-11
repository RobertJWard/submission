# INPUT=$1
# INPUTS="151X_preHCAL 151X_postHCAL"
# INPUTS="151X_noHCALStep 151X_rerunHCALStep 151X_newHCALStep 151pre4_P2GT"
# INPUTS="151X_noHCALStep_retry 151X_rerunHCALStep_retry 151X_newHCALStep_retry"
# INPUTS="151pre4_P2GT_retry 151pre4_P2GTupdate1"
# INPUTS="151pre4_P2GTupdate4"
# INPUTS="151pre4_retry"
# INPUTS="151pre4_VBF 160pre1_VBF"
# INPUTS="170pre1"
# INPUTS="170pre1_MuonOMTF 161pre4 161pre3"
# INPUTS="170pre1_NGJetModel 161pre4_MuonGMT 161pre4_CorrEmu"
# INPUTS="170pre2"
INPUTS="170pre3"
# INPUTS="170pre1_MuonOMTFUpdate1"
# INPUTS="170pre2_JetWord"
# INPUTS="170pre3_3rdTrain"

# Usage: hadd.sh [--timestamp]
#   default:     manifest mode - tracks exactly which files were included (safe against duplicates)
#   --timestamp: timestamp mode - includes any input file newer than the hadd output (best-effort,
#                may miss files delivered during the original hadd run)
USE_TIMESTAMP=false
[ "$1" = "--timestamp" ] && USE_TIMESTAMP=true
echo "Mode: $([ "$USE_TIMESTAMP" = true ] && echo 'timestamp' || echo 'manifest')"

REVISION=$(date +%y%m%d)

TEMP=$(mktemp -d)
echo "Temp directory is $TEMP"

MAX_JOBS=12
PARENTDIR="/eos/cms/store/group/dpg_trigger/comm_trigger/L1Trigger/roward/phase2/menu/ntuples/Spring24"

haddFiles() {
    local sample="$1"
    local temp=${sample#*v45/}
    local sampleShort=${temp%%_TuneCP5*}
    local tempPU=${sample#*Spring24_}
    local samplePU=${tempPU%%_V45*}
    echo -e "Sample: $sampleShort\nPU: $samplePU\nDirectory: $sample" |& tee -a logs/hadd_${INPUT}_${REVISION}.log
    local hadddir=${sample/0000/hadd}
    local haddfile=$hadddir/output_Phase2_L1T.root
    local manifest=$hadddir/hadd_inputs.txt

    if [ -d $hadddir ]; then
        local new_files=()
        if [ "$USE_TIMESTAMP" = true ]; then
            mapfile -t new_files < <(find "$sample" -name "output_*.root" -newer "$haddfile")
        else
            for f in $sample/output_*.root; do
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
        mkdir $hadddir
        local all_files=($sample/output_*.root)
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
    for sample in $(find "$PARENTDIR/$INPUT/v45/" -wholename "*_TuneCP5*/0000" ! -wholename "*LongLived*"); do
        while [ $(jobs -p | wc -l) -ge $MAX_JOBS ]; do
            sleep 3
        done
        haddFiles "$sample" &
    done
done

wait
