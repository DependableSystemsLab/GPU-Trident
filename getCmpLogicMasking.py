#! /usr/bin/python

import subprocess, os, sys

####################################################################
src_name = sys.argv[1]
targetCmpIndex = int(sys.argv[2])
####################################################################

ltCmpList = []
storeMaskingMap = {}

if_cmp = False

# Read "loop_terminating_cmp_list.txt" first
with open("results/loop_terminating_cmp_list.txt", 'r') as lf:
    ltLines = lf.readlines()
    for ltLine in ltLines:
        ltIndex = int( ltLine.split(" ")[1].replace("\n", "") )
        ltCmpList.append(ltIndex)

# Read "store_masking.txt"
with open("results/store_masking.txt", 'r') as sf:
    smLines = sf.readlines()
    for smLine in smLines:
        if " " in smLine:
            storeIndex = int(smLine.split(" ")[0])
            maskingRate = float(smLine.split(" ")[1].replace("\n", ""))
            storeMaskingMap[storeIndex] = maskingRate

diffLines = ""
# None-loop-terminating cmp
if targetCmpIndex not in ltCmpList:
    # DEBUG
    print("Non-loop-terminating CMP: ")
    
    flagHeader = "CICC_MODIFY_OPT_MODULE=1 LD_PRELOAD=./libnvcc.so nvcc -arch=sm_30 -rdc=true -dc -g -G -Xptxas -O0 -D BAMBOO_PROFILING -I ."
    ktraceFlag = " -D KERNELTRACE"
    makeCommand1 = "CMP_PROB_FLIE=results/profile_cmp_prob_result.txt LTCMP_FILE=results/loop_terminating_cmp_list.txt " + "S_INDEX=" + str(targetCmpIndex) + " " + flagHeader + " " + src_name + " -o temp.o" + ktraceFlag
    
    file_list = os.listdir("libs/nonLoopTrmSolver/lib")

    os.system("cp libs/nonLoopTrmSolver/lib/* .")

    #p = subprocess.Popen(makeCommand1, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    diffLines = subprocess.check_output(makeCommand1, shell=True)
    diffLines  = diffLines.decode("utf-8")
    #print "DL output:"
    print(diffLines)
    
    # Clean the copied files
    for file in file_list:
        os.remove(file)

    # Clean produced file
    os.remove("temp.o")
    os.remove("opt_bamboo_after.ll")
    os.remove("opt_bamboo_before.ll")
    
# Loop-terminating cmp
else:
    # DEBUG
    print("Loop-terminating CMP: ") 

    flagHeader = "CICC_MODIFY_OPT_MODULE=1 LD_PRELOAD=./libnvcc.so nvcc -arch=sm_30 -rdc=true -dc -g -G -Xptxas -O0 -D BAMBOO_PROFILING -I ."
    ktraceFlag = " -D KERNELTRACE"
    makeCommand1 = "CMP_PROB_FLIE=results/profile_cmp_prob_result.txt LTCMP_FILE=results/loop_terminating_cmp_list.txt " + "S_INDEX=" + str(targetCmpIndex) + " " + flagHeader + " " + src_name + " -o temp.o" + ktraceFlag
    
    file_list = os.listdir("libs/loopTrmSolver/lib")

    os.system("cp libs/loopTrmSolver/lib/* .")

    #p = subprocess.Popen(makeCommand1, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    diffLines = subprocess.check_output(makeCommand1, shell=True)
    diffLines  = diffLines.decode("utf-8")
    #print diffLines  
    
    # Clean the copied files
    for file in file_list:
        os.remove(file)

    # Clean produced file
    os.remove("temp.o")
    os.remove("opt_bamboo_after.ll")
    os.remove("opt_bamboo_before.ll")
    
print("..........")

# Read "profile_cmp_prob_result.txt"
with open("readable_indexed.ll", 'r') as cmpf:
    pcLines = cmpf.readlines()
    for pcLine in pcLines:
        if ("@profileCount(i64 " + str(targetCmpIndex) + ")") in pcLine:
            if_cmp = True
            break;
    cmpf.close()

# Signal that it is a phi instruction
if if_cmp != True:
    print(-1)
    sys.exit()

# Process results
if "SDC 1" in diffLines or "Loop" in diffLines:
    print(0)
    sys.exit()

if " " not in diffLines:
    if targetCmpIndex in ltCmpList:
        print(0)
    else:
        print(1)
    sys.exit()

accumSdc = 0
for dline in diffLines.split("\n"):
    if " " in dline:
        storeIndex = int(dline.split(" ")[0])
        storeAffectedRate = float(dline.split(" ")[1])
        storeContr = 0
        storeSdc = 1

        if targetCmpIndex in ltCmpList:
            # LT CMP, use 1 as store sdc rate
            storeSdc = 1
        else:
            # NLT CMP
            if storeIndex in storeMaskingMap:
                storeSdc = 1 - storeMaskingMap[storeIndex]
        storeContr = storeAffectedRate * storeSdc
        accumSdc += storeContr  
        print(" >>> Store found: " + str(storeIndex) + ", storeSdc: " + str(storeSdc) + ", storeContr: " + str(storeContr))
        
if accumSdc >= 1:
    print(0)
else:
    print((1-accumSdc))











