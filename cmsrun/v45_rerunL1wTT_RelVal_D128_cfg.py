# Auto generated configuration file
# using: 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: l1nanoPhase2 -s NANO:@Phase2L1DPGwithGen --procModifiers nano_l1_hlt --conditions auto:phase2_realistic --geometry ExtendedRun4D128 --era Phase2C17I13M9 --eventcontent NANOAODSIM --datatier NANOAODSIM --customise_commands 'del process.sc4NGJetTable\ndel process.dispVtxTable\ndel process.KMTFpromptMuTable\ndel process.KMTFDisplaceMuTable\ndel process.OMTFpromptMuTable\ndel process.OMTFDisplaceMuTable\ndel process.EMTFpromptMuTable\ndel process.EMTFDisplaceMuTable\nprocess.finalGenParticles.src = '"'"'genParticles'"'"'\nprocess.genJetTable.src = '"'"'ak4GenJetsNoNu'"'"'\ndelattr(process.genParticleTable.externalVariables,'"'"'iso'"'"')\ndel process.genIso\ndel process.genJetFlavourTable\ndel process.patJetPartonsNano\nimport FWCore.ParameterSet.Config as cms; from PhysicsTools.NanoAOD.simpleSingletonCandidateFlatTableProducer_cfi import simpleSingletonCandidateFlatTableProducer; from PhysicsTools.NanoAOD.common_cff import PTVars; process.metMCTable = simpleSingletonCandidateFlatTableProducer.clone(src='"'"'genMetTrue'"'"', name='"'"'GenMET'"'"', doc='"'"'Gen MET'"'"', variables=cms.PSet(PTVars)); from PhysicsTools.NanoAOD.jetMC_cff import genJetAK8Table as _ak8; process.genJetAK8Table = _ak8.clone(src='"'"'ak8GenJetsNoNu'"'"', doc='"'"'AK8 gen jets (no nu)'"'"', cut='"'"'pt > 10'"'"'); process.genExtra_step = cms.Path(process.metMCTable + process.genJetAK8Table); process.schedule.append(process.genExtra_step)' --filein /store/relval/CMSSW_20_0_0_patch1/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/150X_mcRun4_realistic_v1_STD_D128_RecycledGEN_noPU_16Aug26-v4/2590000/0279aef6-447a-476a-b596-8e123e3f0575.root --fileout file:output_Phase2_L1T.root --python_filename v45_rerunL1wTT_RelVal_D128_cfg.py --mc -n 40 --nThreads 4
import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Phase2C17I13M9_cff import Phase2C17I13M9
from Configuration.ProcessModifiers.nano_l1_hlt_cff import nano_l1_hlt

process = cms.Process('NANO',Phase2C17I13M9,nano_l1_hlt)

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('SimGeneral.MixingModule.mixNoPU_cfi')
process.load('Configuration.Geometry.GeometryExtendedRun4D128Reco_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(40),
    output = cms.optional.untracked.allowed(cms.int32,cms.PSet)
)

# Input source
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('/store/relval/CMSSW_20_0_0_patch1/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/150X_mcRun4_realistic_v1_STD_D128_RecycledGEN_noPU_16Aug26-v4/2590000/0279aef6-447a-476a-b596-8e123e3f0575.root'),
    secondaryFileNames = cms.untracked.vstring()
)

process.options = cms.untracked.PSet(
    IgnoreCompletely = cms.untracked.vstring(),
    Rethrow = cms.untracked.vstring(),
    TryToContinue = cms.untracked.vstring(),
    accelerators = cms.untracked.vstring('*'),
    allowUnscheduled = cms.obsolete.untracked.bool,
    canDeleteEarly = cms.untracked.vstring(),
    deleteNonConsumedUnscheduledModules = cms.untracked.bool(True),
    dumpOptions = cms.untracked.bool(False),
    emptyRunLumiMode = cms.obsolete.untracked.string,
    eventSetup = cms.untracked.PSet(
        forceNumberOfConcurrentIOVs = cms.untracked.PSet(
            allowAnyLabel_=cms.required.untracked.uint32
        ),
        numberOfConcurrentIOVs = cms.untracked.uint32(0)
    ),
    fileMode = cms.untracked.string('FULLMERGE'),
    forceEventSetupCacheClearOnNewRun = cms.untracked.bool(False),
    holdsReferencesToDeleteEarly = cms.untracked.VPSet(),
    makeTriggerResults = cms.obsolete.untracked.bool,
    modulesToCallForTryToContinue = cms.untracked.vstring(),
    modulesToIgnoreForDeleteEarly = cms.untracked.vstring(),
    numberOfConcurrentLuminosityBlocks = cms.untracked.uint32(0),
    numberOfConcurrentRuns = cms.untracked.uint32(1),
    numberOfStreams = cms.untracked.uint32(0),
    numberOfThreads = cms.untracked.uint32(1),
    printDependencies = cms.untracked.bool(False),
    sizeOfStackForThreadsInKB = cms.optional.untracked.uint32,
    throwIfIllegalParameter = cms.untracked.bool(True),
    wantSummary = cms.untracked.bool(False)
)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    annotation = cms.untracked.string('l1nanoPhase2 nevts:40'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# Output definition

process.NANOAODSIMoutput = cms.OutputModule("NanoAODOutputModule",
    compressionAlgorithm = cms.untracked.string('LZMA'),
    compressionLevel = cms.untracked.int32(9),
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string('NANOAODSIM'),
        filterName = cms.untracked.string('')
    ),
    fileName = cms.untracked.string('file:output_Phase2_L1T.root'),
    outputCommands = process.NANOAODSIMEventContent.outputCommands
)

# Additional output definition

# Other statements
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'auto:phase2_realistic', '')

# Path and EndPath definitions
process.nanoAOD_step = cms.Path(process.l1tPh2NanoSequence)
process.endjob_step = cms.EndPath(process.endOfProcess)
process.NANOAODSIMoutput_step = cms.EndPath(process.NANOAODSIMoutput)

# Schedule definition
process.schedule = cms.Schedule(process.nanoAOD_step,process.endjob_step,process.NANOAODSIMoutput_step)
from PhysicsTools.PatAlgos.tools.helpers import associatePatAlgosToolsTask
associatePatAlgosToolsTask(process)

#Setup FWK for multithreaded
process.options.numberOfThreads = 4
process.options.numberOfStreams = 0

# customisation of the process.

# Automatic addition of the customisation function from DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff
from DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff import addPh2L1Objects,addPh2GTObjects,addGenObjects 

#call to customisation function addPh2L1Objects imported from DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff
process = addPh2L1Objects(process)

#call to customisation function addPh2GTObjects imported from DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff
process = addPh2GTObjects(process)

#call to customisation function addGenObjects imported from DPGAnalysis.Phase2L1TNanoAOD.l1tPh2Nano_cff
process = addGenObjects(process)

# End of customisation functions


# Customisation from command line

del process.sc4NGJetTable
del process.dispVtxTable
del process.KMTFpromptMuTable
del process.KMTFDisplaceMuTable
del process.OMTFpromptMuTable
del process.OMTFDisplaceMuTable
del process.EMTFpromptMuTable
del process.EMTFDisplaceMuTable
process.finalGenParticles.src = 'genParticles'
process.genJetTable.src = 'ak4GenJetsNoNu'
delattr(process.genParticleTable.externalVariables,'iso')
del process.genIso
del process.genJetFlavourTable
del process.patJetPartonsNano
import FWCore.ParameterSet.Config as cms; from PhysicsTools.NanoAOD.simpleSingletonCandidateFlatTableProducer_cfi import simpleSingletonCandidateFlatTableProducer; from PhysicsTools.NanoAOD.common_cff import PTVars; process.metMCTable = simpleSingletonCandidateFlatTableProducer.clone(src='genMetTrue', name='GenMET', doc='Gen MET', variables=cms.PSet(PTVars)); from PhysicsTools.NanoAOD.jetMC_cff import genJetAK8Table as _ak8; process.genJetAK8Table = _ak8.clone(src='ak8GenJetsNoNu', doc='AK8 gen jets (no nu)', cut='pt > 10'); process.genExtra_step = cms.Path(process.metMCTable + process.genJetAK8Table); process.schedule.append(process.genExtra_step)
process.source.delayReadingEventProducts = cms.untracked.bool(False)
# Add early deletion of temporary data products to reduce peak memory need
from Configuration.StandardSequences.earlyDeleteSettings_cff import customiseEarlyDelete
process = customiseEarlyDelete(process)
# End adding early deletion
