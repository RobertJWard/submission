# dasgoclient -query="dataset=/HTo2LongLivedTo2mu2jet*/*Spring24*/GEN-SIM-DIGI-RAW-MINIAOD" |& tee logs/HTo2LongLivedTo2mu2jet.log
# dasgoclient -query="dataset=/HTo2LongLivedTo4mu*/*Spring24*/GEN-SIM-DIGI-RAW-MINIAOD" |& tee logs/HTo2LongLivedTo4mu.log

dasgoclient -query="dataset=/*14TeV*/*Phase2Spring24*PU*/GEN-SIM-DIGI-RAW-MINIAOD" |& tee logs/phase2.log

