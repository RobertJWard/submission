
import pickle
import optparse
# import imp # removed in python 3.12
import importlib.util
import traceback


def pickler(input_file, output_file):
    print('input {}'.format(input_file))
    print('output {}'.format(output_file))

    # handle = open(input_file, 'r') # obsolete in python 3.12
    # cfo = imp.load_source("pycfg", input_file, handle) # obsolete in python 3.12
    spec = importlib.util.spec_from_file_location("pycfg", input_file)
    cfo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cfo)
    cmsProcess = cfo.process
    # handle.close()

    pklFile_name = '{}.pkl'.format(output_file.split('.')[0])
    pklFile = open(pklFile_name, "wb")
    psetFile = open(output_file, "w")
    try:
        pickle.dump(cmsProcess, pklFile)
        psetFile.write("import FWCore.ParameterSet.Config as cms\n")
        psetFile.write("import pickle\n")
        psetFile.write("handle = open('{}', 'rb')\n".format(pklFile_name))
        psetFile.write("process = pickle.load(handle)\n")
        psetFile.write("handle.close()\n")
        psetFile.close()
    except Exception as ex:
        print("Error writing out PSet:")
        print(traceback.format_exc())
        raise ex
    finally:
        psetFile.close()
        pklFile.close()


def main():
    usage = ('usage: %prog [options]\n'
             + '%prog -h for help')
    parser = optparse.OptionParser(usage)
    # parser.add_option('-f', '--file', dest='CONFIGFILE', help='specify the ini configuration file')
    # parser.add_option("--create", action="store_true", dest="CREATE", default=False, help="create the job configuration")
    # parser.add_option("--submit", action="store_true", dest="SUBMIT", default=False, help="submit the jobs to condor")
    # parser.add_option("--status", action="store_true", dest="STATUS", default=False, help="check the status of the condor tasks")

    global opt, args
    (opt, args) = parser.parse_args()

    input_file = args[0]
    output_file = args[1]
    pickler(input_file, output_file)

if __name__ == "__main__":
    main()
