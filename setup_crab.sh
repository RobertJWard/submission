# eval `scram runtime -sh`
# source /cvmfs/cms.cern.ch/crab3/crab.sh
# voms-proxy-init --voms cms --valid 168:00

# Check if a valid VOMS proxy exists
# --acexists cms also checks the proxy's CMS attribute, --valid renews it when less than a day is left
if ! voms-proxy-info --exists --valid 24:00 --acexists cms &>/dev/null; then
    echo "No valid VOMS proxy, setting one up"
    voms-proxy-init --voms cms --valid 168:00
else
    echo "VOMS Proxy found!"
fi
