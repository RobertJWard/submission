#NOTE: put threads=4 here which differs to testing (and n=40 to check it works!)
INPUT=/store/mc/Phase2Spring24DIGIRECOMiniAOD/TT_TuneCP5_14TeV-powheg-pythia8/GEN-SIM-DIGI-RAW-MINIAOD/PU200_AllTP_140X_mcRun4_realistic_v4-v1/2560000/11d1f6f0-5f03-421e-90c7-b5815197fc85.root

# out-the-box command using withGen option
cmsDriver.py l1nanoPhase2 -s L1TrackTrigger,L1,L1P2GT,NANO:@Phase2L1DPGwithGen --processName L1TReRun --conditions auto:phase2_realistic --geometry ExtendedRun4D121 --era Phase2C17I13M9 --eventcontent NANOAOD --datatier GEN-SIM-DIGI-RAW-MINIAOD --customise SLHCUpgradeSimulations/Configuration/aging.customise_aging_1000,Configuration/DataProcessing/Utils.addMonitoring,L1Trigger/Configuration/customisePhase2TTOn110.customisePhase2TTOn110 --filein $INPUT --fileout file:output_Phase2_L1T.root --python_filename v45_rerunL1wTT_AR26_cfg.py --inputCommands="keep *, drop l1tPFJets_*_*_*, drop l1tTrackerMuons_l1tTkMuonsGmt*_*_HLT" --mc -n 40 --nThreads 4

# --outputCommands="drop *, keep *_l1tTTTracksFromTrackletEmulation_*_*" 
