from CRABClient.UserUtilities import config
config = config()

# config.General.requestName = 'SingleGammaPt25Eta1p6_2p8_PU0'
# config.Data.inputDataset = '/SingleGammaPt25Eta1p6_2p8/PhaseIITDRFall17DR-noPUFEVT_93X_upgrade2023_realistic_v2-v1/GEN-SIM-DIGI-RAW'

config.General.requestName = 'TEMPL_REQUESTNAME'
config.Data.inputDataset = 'TEMPL_INPUTDATASET'

config.General.workArea = 'TEMPL_TASKDIR'
config.General.transferOutputs = True
config.General.transferLogs = False

config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'TEMPL_TASKCONFDIR/input_cfg.py'
config.JobType.maxMemoryMB = 8000
config.JobType.numCores = 4

config.Data.inputDBS = 'global'
config.Data.splitting = 'TEMPL_SPLITTINGMODE'
config.Data.unitsPerJob = TEMPL_SPLITGRANULARITY
config.Data.totalUnits = TEMPL_NEVENTS
config.Data.outLFNDirBase = 'TEMPL_CRABOUTDIR'
config.Data.publication = False
config.Data.ignoreLocality = False
config.Data.outputDatasetTag = 'TEMPL_DATASETTAG'

config.Data.partialDataset = True

# config.Site.storageSite = 'T3_CH_CERNBOX'
config.Site.storageSite = 'T2_CH_CERN'
config.JobType.allowUndistributedCMSSW = True

config.Data.allowNonValidInputDataset = True
