FILE=sampleLists/tapeOnlyStripped.txt

while IFS= read -r dataset; do
  echo "Dataset: $dataset"
  dasgoclient -query="summary dataset=$dataset" \
      | python3 -c "import json, sys
s = json.load(sys.stdin)[0]['file_size']
for unit in ['B','KB','MB','GB','TB','PB']:
    if s < 1024.0: print(f'{s:.2f} {unit}'); break
    s /= 1024.0"
  echo
done < $FILE
