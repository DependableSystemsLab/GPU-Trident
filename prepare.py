import os, subprocess, sys

PROGRAM_NAME = "example"
PROGRAM_OUTPUT_NAME = "result.txt" 
inputParameters = ""
LLVM_PATH = "/home/abdul/GPU-Trident/llvm-install"

SRC_NAME = " "+ PROGRAM_NAME + ".cu "
OBJ_NAME = PROGRAM_NAME + ".o "
OUT_NAME = PROGRAM_NAME + ".out "


#############################################################################
flagHeader = "CICC_MODIFY_OPT_MODULE=1 LD_PRELOAD=./libnvcc.so nvcc -arch=sm_30 -rdc=true -dc -g -G -Xptxas -O0 -D BAMBOO_PROFILING -I ."
ktraceFlag = " -D KERNELTRACE"
linkFlags = ""
optFlags = ""
#############################################################################
makeCommand1 = flagHeader + SRC_NAME + "-o " + OBJ_NAME + ktraceFlag

def collectData(dir_name, result_name, keep_after_ll):

    if result_name != "":
        if (os.path.exists("results/" + result_name)):
            os.remove("results/" + result_name)
    
    file_list = os.listdir("libs/" + dir_name +"/lib")

    os.system("cp libs/" + dir_name + "/lib/* .")

    os.system(makeCommand1)
    os.system("nvcc -arch=sm_30 " +  dir_name + ".cu -c -dc -O0")
    os.system("nvcc -arch=sm_30 " + dir_name + ".o " + OBJ_NAME + " -o " + OUT_NAME + " -O0")

    goldenOutput = subprocess.check_output("./" + OUT_NAME + " " + inputParameters, shell=True)
    #print goldenOutput

    # Clean the copied files
    for file in file_list:
        os.remove(file)

    # Clean the produced files
    os.remove(PROGRAM_NAME + ".out")
    os.remove(PROGRAM_NAME + ".o")
    os.remove(dir_name + ".o")
    os.remove("opt_bamboo_before.ll")
    
    if (keep_after_ll == False):
        os.remove("opt_bamboo_after.ll")
    else:
        os.rename('opt_bamboo_after.ll', 'indexed.ll')

    if result_name != "":
        # Move the results to another directory 
        os.system("mv " + result_name + " results/")
    
    if PROGRAM_OUTPUT_NAME != "":
        os.remove(PROGRAM_OUTPUT_NAME)

def profile():
    
    # Index the instructions and get the IR file
    collectData("instIndexer", "", True)
    
    # Convert opt_bamboo_after.ll into readable format
    os.system(LLVM_PATH + "/bin/llvm-dis indexed.ll -o readable_indexed.ll")
    os.remove("indexed.ll")
    
    # Record load and store instruction and crash rate "Temp here"
    os.system("python find_load_store.py > results/crash_rate.txt")
    
    # Profile the nummber of times each instruction is called
    collectData("instCount", "instCountResult.txt", False)
    
    # Produce fi_breakdown.txt, if it is already present delete it
    if (os.path.exists("results/fi_breakdown.txt")):
        os.remove("results/fi_breakdown.txt")
        
    with open("results/instCountResult.txt", 'r') as rf:
        lines = rf.readlines()
        for line in lines:
            if ":" not in line:
                continue
            with open("results/fi_breakdown.txt", 'a') as wf:
                index = line.split(": ")[0]
                count = line.split(": ")[1].replace("\n", "")
                wf.write("-- FI Index: " + index + ", : , : , : , Total FI: " + count + "\n")
    
    # Profile the number of time compare instructions resolve to 1 or 0
    collectData("callCount", "profile_call_prob_result.txt",False)
    
    # Profile the number of time compare instructions resolve to 1 or 0
    collectData("cmpProb", "profile_cmp_prob_result.txt",False)
    
    # Profile the average value of arguments of compare instructions
    collectData("cmpVal", "profile_cmp_value_result.txt", False)
    
    # Profile the average value of arguments of compare instructions
    collectData("shftVal", "profile_shift_value_result.txt", False)
    
    # Run resolveCmpProb.py script
    os.system("python resolveCmpProb.py readable_indexed.ll")
    
    # Find the tuples for instructions
    os.system("python getInstTuples.py readable_indexed.ll")
    
    # Simplify instruction Tuples
    os.system("python simplifyInstTuples.py")
    
    # Profile the load and store addreses
    collectData("memPro", "profile_mem_result.txt", False)
    

def execute_trident():
    
    print "\n*********************************\nTracing memory level propagation ...\n\n"
    os.system("python getStoreMaskingRate.py " + PROGRAM_NAME + ".cu")
    
    # Validating model at 3 level
    print "\n*********************************\nValiadating model at 3 levels, fi_breakdown.txt must be in place for the input. Results will be in prediction.results ...\n\n"
    os.system("python validateModel.py " + PROGRAM_NAME + ".cu" + " > results/prediction.results ")

if __name__ == "__main__":

    if sys.argv[1] == '1':
        profile()
    
    elif sys.argv[1] == '2': 
        execute_trident()
    
    else:
        print "\n\nWrong input argument\n"
