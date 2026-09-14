SUBMISSION=$1

# Check current release
source scripts/checkRelease.sh

python3 submit.py -f $SUBMISSION --create
python3 submit.py -f $SUBMISSION --submit
