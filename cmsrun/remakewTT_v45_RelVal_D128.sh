#NOTE: put threads=4 here which differs to testing (and n=40 to check it works!)
INPUT=/store/relval/CMSSW_20_0_0_patch1/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/150X_mcRun4_realistic_v1_STD_D128_RecycledGEN_noPU_16Aug26-v4/2590000/0279aef6-447a-476a-b596-8e123e3f0575.root

# customised RelVal command using withGen option
cmsDriver.py l1nanoPhase2 -s NANO:@Phase2L1DPGwithGen --procModifiers nano_l1_hlt \
  --conditions auto:phase2_realistic --geometry ExtendedRun4D128 --era Phase2C17I13M9 \
  --eventcontent NANOAODSIM --datatier NANOAODSIM \
  --customise_commands "del process.sc4NGJetTable\ndel process.dispVtxTable\ndel process.KMTFpromptMuTable\ndel process.KMTFDisplaceMuTable\ndel process.OMTFpromptMuTable\ndel process.OMTFDisplaceMuTable\ndel process.EMTFpromptMuTable\ndel process.EMTFDisplaceMuTable\nprocess.finalGenParticles.src = 'genParticles'\nprocess.genJetTable.src = 'ak4GenJetsNoNu'\ndelattr(process.genParticleTable.externalVariables,'iso')\ndel process.genIso\ndel process.genJetFlavourTable\ndel process.patJetPartonsNano\nimport FWCore.ParameterSet.Config as cms; from PhysicsTools.NanoAOD.simpleSingletonCandidateFlatTableProducer_cfi import simpleSingletonCandidateFlatTableProducer; from PhysicsTools.NanoAOD.common_cff import PTVars; process.metMCTable = simpleSingletonCandidateFlatTableProducer.clone(src='genMetTrue', name='GenMET', doc='Gen MET', variables=cms.PSet(PTVars)); from PhysicsTools.NanoAOD.jetMC_cff import genJetAK8Table as _ak8; process.genJetAK8Table = _ak8.clone(src='ak8GenJetsNoNu', doc='AK8 gen jets (no nu)', cut='pt > 10'); process.genExtra_step = cms.Path(process.metMCTable + process.genJetAK8Table); process.schedule.append(process.genExtra_step)" \
  --filein $INPUT --fileout file:output_Phase2_L1T.root \
  --python_filename v45_rerunL1wTT_RelVal_D128_cfg.py --mc -n 40 --nThreads 4
