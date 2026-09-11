# FILE=datasets_bbvv_fordasgo.txt
FILE=sampleLists/relValSamples.txt
# FILE=sampleLists/spring24Samples.txt

while IFS= read -r dataset; do
  echo "Dataset: $dataset"
  dasgoclient -query="summary dataset=$dataset"
  echo
done < $FILE


# append to get explicitly the file size
  #  \
#       | python3 -c "import json, sys
# s = json.load(sys.stdin)[0]['file_size']
# for unit in ['B','KB','MB','GB','TB','PB']:
#     if s < 1024.0: print(f'{s:.2f} {unit}'); break
#     s /= 1024.0"
