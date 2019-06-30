import os, subprocess, shutil, sys

# Import user provided configuration 
from config import PROGRAM_NAME, PROGRAM_OUTPUT_NAME, INPUT_PARAMETERS, LLVM_PATH
from config_gen import SHARED_MEM_USE

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

    goldenOutput = subprocess.check_output("./" + OUT_NAME + " " + INPUT_PARAMETERS, shell=True)
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

def prune_threads():

    first_stage = True
    stores = []
    loads = []

    param_file = open("local_param.h")

    for line in param_file:
        if "START_LOOP" in line:
            line = line.split(" ")
            if int(line[2]) == 0:
                first_stage = False
    
    if first_stage == True:

        # Control flow inside loop steps
        collectData("controlFlow-1", "control_flow_group-1.txt", False)

    collectData("controlFlow-2", "control_flow_group-2.txt", False)

    xIDs = []
    yIDs = []
    invo_count = []
    representative_threads = []
    
    arg = "True" if (param_file == True) else "False"

    # Extract representative threads
    output = subprocess.check_output("python parse.py " + arg, shell=True)

    output = output.replace(" ", "")
    
    representative_threads = output.splitlines()

    for thread in representative_threads:
        indices = thread[1:-1]
        indices = indices.split(',')
        xIDs.append(int(indices[1]))
        yIDs.append(int(indices[2]))
        invo_count.append(int(indices[0]))

    shared_ls = open("shared_mem.txt")

    for line in shared_ls:
        line = line.strip()
        line = line.split(" ")

        if line[1] == 'L':
            loads.append(line[0])
        else:
            stores.append(line[0])

    # Construct conditional for memory profiling
    cond_str = "if("

    for iterator in range(len(xIDs)):
        cond = "(idx == " + str(xIDs[iterator]) + " \&\& " "call_count == " + str(invo_count[iterator]) + " \&\& " "idy == " + str(yIDs[iterator])+ ")"
        if iterator != (len(xIDs) - 1):
            cond += ' || '

        cond_str += cond

    cond_str += ")"

    if (os.path.exists("libs/memPro")):
        os.system("rm -rf libs/memPro")
        
    os.system("cp -r libs/memPro_std libs/memPro")

    command = "sed -i 's/if (COND)/" + cond_str + "/' libs/memPro/lib/memPro.cu"
    os.system(command)

    # Put filter for shared loads
    cond_str = "if(!("

    for iterator in range(len(loads)):
        cond = "index==" + loads[iterator]
        if iterator != (len(loads) - 1):
            cond += ' || '

        cond_str += cond

    cond_str += "))"

    command = "sed -i 's/if (LOAD)/" + cond_str + "/' libs/memPro/lib/memPro.cu"

    os.system(command)

    # Put filter for shared stores
    cond_str = "if(!("

    for iterator in range(len(stores)):
        cond = "index==" + stores[iterator]
        if iterator != (len(stores) - 1):
            cond += ' || '

        cond_str += cond

    cond_str += "))"

    command = "sed -i 's/if (STORE)/" + cond_str + "/' libs/memPro/lib/memPro.cu"

    os.system(command)

    # Profile the load and store addreses
    collectData("memPro", "profile_mem_result.txt", False)

    # If benchmark uses shared memory
    if SHARED_MEM_USE == True:

        # Rename the previous memory trace
        os.rename("results/profile_mem_result.txt", "results/profile_mem_result.txt_1")

        # Construct conditional for memory profiling
        cond_str = "if("

        for iterator in range(len(xIDs)):
            cond = "(BX==((TX-" + str(xIDs[iterator]) + ")\/DX))" + " \&\& " "call_count == " + str(invo_count[iterator]) + " \&\& " "(BY==((TY-" + str(yIDs[iterator]) + ")\/DY))"
            if iterator != (len(xIDs) - 1):
                cond += ' || '

            cond_str += cond

        cond_str += ")"

        if (os.path.exists("libs/memPro")):
            os.system("rm -rf libs/memPro")
        
        os.system("cp -r libs/memPro2_std libs/memPro")

        command = "sed -i 's/if (COND)/" + cond_str + "/' libs/memPro/lib/memPro.cu"

        os.system(command)

        # Filter for shared loads
        cond_str = "if("

        for iterator in range(len(loads)):
            cond = "index==" + loads[iterator]
            if iterator != (len(loads) - 1):
                cond += ' || '

            cond_str += cond

        cond_str += ")"

        command = "sed -i 's/if (LOAD)/" + cond_str + "/' libs/memPro/lib/memPro.cu"

        os.system(command)

        # Filter for shared stores
        cond_str = "if("

        for iterator in range(len(stores)):
            cond = "index==" + stores[iterator]
            if iterator != (len(stores) - 1):
                cond += ' || '

            cond_str += cond

        cond_str += ")"

        command = "sed -i 's/if (STORE)/" + cond_str + "/' libs/memPro/lib/memPro.cu"

        os.system(command)

        # Profile the load and store addreses
        collectData("memPro", "profile_mem_result.txt", False)

        os.rename("results/profile_mem_result.txt", "results/profile_mem_result.txt_2")

        # Concatenate the two memory traces
        os.system("cat results/profile_mem_result.txt_1 results/profile_mem_result.txt_2 > results/profile_mem_result.txt" )

        # Removing the files
        os.remove("results/profile_mem_result.txt_1")
        os.remove("results/profile_mem_result.txt_2")



def profile():

    # Profile the nummber of times each instruction is called
    collectData("instCount", "instCountResult.txt", False)

    # Profile the average value of arguments of compare instructions
    collectData("cmpVal", "profile_cmp_value_result.txt", False)

    # Profile the nummber of times each instruction is called
    collectData("instCount", "instCountResult.txt", False)
    
    # Record load and store instruction and crash rate "Temp here"
    os.system("python find_load_store.py > results/crash_rate.txt")
    
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
    #collectData("callCount", "profile_call_prob_result.txt",False)
    
    # Profile the number of time compare instructions resolve to 1 or 0
    collectData("cmpProb", "profile_cmp_prob_result.txt",False)
    
    # Profile the average value of arguments of compare instructions
    collectData("shftVal", "profile_shift_value_result.txt", False)
    
    # Run resolveCmpProb.py script
    os.system("python resolveCmpProb.py readable_indexed.ll")
    
    # Find the tuples for instructions
    os.system("python getInstTuples.py readable_indexed.ll")
    
    # Simplify instruction Tuples
    os.system("python simplifyInstTuples.py")
    
    prune_threads()
    
    os.rename("results/profile_mem_result.txt", "results/profile_mem_result_1.txt")
    
    memFile = open("results/profile_mem_result_1.txt")
    newFile = ""
    
    for line in memFile:
        if "(nil)" in line:
            newFile += line.replace('(nil)', '0x0')
        else:
            newFile += line
            
    mem_f = open("results/profile_mem_result.txt", 'w')
    mem_f.write(newFile)
    mem_f.close()
    
    os.remove("results/profile_mem_result_1.txt")
    
def execute_trident():
    
    print "\n*********************************\nTracing memory level propagation ...\n\n"
    os.system("python getStoreMaskingRate.py " + PROGRAM_NAME + ".cu")
    
    # Validating model at 3 level
    print "\n*********************************\nValiadating model at 3 levels, fi_breakdown.txt must be in place for the input. Results will be in prediction.results ...\n\n"
    os.system("python validateModel.py " + PROGRAM_NAME + ".cu" + " > results/prediction.results ")

# Main function
if __name__ == "__main__":

    if sys.argv[1] == 'index':

        # Index the instructions and get the IR file
        collectData("instIndexer", "", True)
    
        # Convert opt_bamboo_after.ll into readable format
        os.system(LLVM_PATH + "/bin/llvm-dis indexed.ll -o readable_indexed.ll")
        os.remove("indexed.ll")
        
    elif sys.argv[1] == 'profile':
        profile()
    
    elif sys.argv[1] == 'execute': 
        execute_trident()
    
    else:
        print "\n\nWrong input argument\n"
