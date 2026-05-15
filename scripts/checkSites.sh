FILE=sampleLists/phase2samples.txt

while IFS= read -r dataset; do
  echo "Dataset: $dataset"
  dasgoclient -query="site dataset=$dataset"
  echo
done < $FILE
