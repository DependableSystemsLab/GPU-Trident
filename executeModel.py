#! /user/bin/python

import sys, os, subprocess
from config import GLOBAL_LOAD_LIST, GLOBAL_STORE_LIST
from shutil import copyfile, rmtree
from config_gen import src_list, domi_list, domi_val

DOMI_CHECK = False
DOMI_INDEX = []

cmp_percent = {}
out_store = False


############################
src_name = sys.argv[1]
targetIndex = int(sys.argv[2])

# Model: SIM, LM, MM

instCountDic = {}
smDic = {} # store masking dic

# Read "profile_call_prob_result.txt"
with open("results/profile_call_prob_result.txt", 'r') as callf:
    pcLines = callf.readlines()
    for pcLine in pcLines:
        index = int(pcLine.split(" ")[0].replace(":", ""))
        totalC = int(pcLine.split(" ")[1])
        instCountDic[index] = totalC
    callf.close()


# Read "store_masking.txt"
with open("results/store_masking.txt", 'r') as sf:
    sLines = sf.readlines()
    for sLine in sLines:
        index = int(sLine.split(" ")[0])
        sm = float(sLine.split(" ")[1])
        totalC = int(sLine.split(" ")[2])
        instCountDic[index] = totalC
        smDic[index] = sm # masking rate of store
    sf.close()

with open("results/fi_breakdown.txt", 'r') as rf:
    lines = rf.readlines()
    for line in lines:
        if "--" in line:
            index = int(line.split("FI Index: ")[1].split(",")[0])
            count = int(line.split("Total FI: ")[1].replace("\n", ""))
            if index not in instCountDic:
                instCountDic[index] = count

# Read "profile_cmp_prob_result.txt"
with open("results/profile_cmp_prob_result.txt", 'r') as cmpf:
    pcLines = cmpf.readlines()
    for pcLine in pcLines:
        index = int(pcLine.split(" ")[0].replace(":", ""))
        c1 = int(pcLine.split(" ")[1])
        c2 = int(pcLine.split(" ")[2])
        totalC = c1 + c2
        instCountDic[index] = totalC
        if index in domi_list:
            if c1 == 0:
                cmp_percent[index] = False
    cmpf.close()



############################################################################
# Run Static-instruction-level Masking (SIM)
############################################################################

flagHeader = "CICC_MODIFY_OPT_MODULE=1 LD_PRELOAD=./libnvcc.so nvcc -arch=sm_30 -rdc=true -dc -g -G -Xptxas -O0 -D BAMBOO_PROFILING -I ."
ktraceFlag = " -D KERNELTRACE"
makeCommand1 = "SHARED_FILE=shared_mem.txt STUPLE_FILE=results/simplified_inst_tuples.txt " + "S_INDEX=" + str(targetIndex) + " " + flagHeader + " " + src_name + " -o temp.o" + ktraceFlag

file_list = os.listdir("libs/staticInstModel/lib")

os.system("cp libs/staticInstModel/lib/* .")

simOutput = subprocess.check_output(makeCommand1, shell=True)
simOutput = simOutput.decode("utf-8")

for num in domi_list:
    if str(num) + " cmp:" in simOutput:
        DOMI_CHECK = True
        DOMI_INDEX.append(domi_list.index(num))

# Clean the copied files
for file in file_list:
    os.remove(file)

# Clean produced file
os.remove("temp.o")
os.remove("opt_bamboo_after.ll")
os.remove("opt_bamboo_before.ll")

totalTmnInstCount = 0
accumSdc = 0
accumCrash = 0
for opLine in simOutput.split("\n"): # Each line is a leaf node of SIM, need weighted at the end
    if " " in opLine:
        indexNType = opLine.split(":")[0]
        instIndex = int(indexNType.split(" ")[0])
        instType = indexNType.split(" ")[1]
    
        # Get all rates from SIM
        # 397 cmp: 0.015324, 0.219051, 0.765625
        # 400 store: 0.054932, 0.179443, 0.765625
        simPR = float( opLine.split(":")[1].split(", ")[0] )
        simMR = float( opLine.split(":")[1].split(", ")[1] ) 
        simCR = float( opLine.split(":")[1].split(", ")[2].replace("\n", "") ) # Crash rate of SIM is used as final crash rate

        instCount = 0
        if instIndex in instCountDic:
            instCount = instCountDic[instIndex]

        if "cmp" in instType:
            print("Inside CMP", instIndex)
            ############################################################################
            # RUN Logic-level Masking:Get logic masking and final benign rate
            ############################################################################
            llCommand = ["python", "getCmpLogicMasking.py", src_name, str(instIndex)]
            p = subprocess.Popen(llCommand, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            llOutput = p.stdout.read()
            llOutput  = llOutput.decode("utf-8")
            llBenign = float(llOutput.split("\n")[-2])

            if llBenign == float(-1):
                llBenign = 0
                if targetIndex in domi_list:
                   instCount = instCountDic[targetIndex]

            llSdc = 1 - llBenign
            sdcContr = llSdc * simPR
            totalTmnInstCount += instCount
            accumSdc += sdcContr * instCount
            accumCrash += simCR * instCount
            print("SDC: cmp " + str(instIndex) + " ------> " + str(sdcContr))
            print("Accum SDC", accumSdc, instCount)

            if (instIndex in cmp_percent) and (instIndex in domi_list):
                cmp_percent[instType] = True

        if "store" in instType:
            ############################################################################
            # Get Store masking rate
            ############################################################################
            sm = 0 # store masking rate
            sPr = 1 # store sdc rate
            if instIndex in smDic:
                sm = smDic[instIndex]
                sPr = 1 - sm
            llBenign = float(sm) 
            llSdc = 1 - llBenign
            sdcContr = llSdc * simPR
            totalTmnInstCount += instCount
            accumSdc += sdcContr * instCount
            accumCrash += simCR * instCount
            print("SDC: store " + str(instIndex) + " ------> " + str(sdcContr))
            print("Accum SDC", accumSdc, instCount)

            # This is the only outputstore
            if instIndex in GLOBAL_STORE_LIST and  len(domi_list) == 1:
                out_store = True


        if "call" in instType:
            if len( indexNType.split(" ") ) >= 3:
                funcName = indexNType.split(" ")[2]
                # Specify SDC
                if "fopen" in funcName or "fputs" in funcName or "fwrite" in funcName or "_IO_putc" in funcName:
                    cPr = 1
                    cMr = 0
                    sdcContr = cPr * simPR
                    totalTmnInstCount += instCount
                    accumSdc += sdcContr * instCount
                    accumCrash += simCR * instCount
                    print("SDC: call " + str(instIndex) + " ------> " + str(sdcContr))

fSdc = 0
fCrash = 0
fBenign = 1

# Calculating and ensuring bounded valeus
if totalTmnInstCount != 0:
    fSdc = accumSdc / float(totalTmnInstCount)
    fCrash = accumCrash / float(totalTmnInstCount)
    fBenign = 1 - fSdc - fCrash
    
    if fSdc < 0:
        fSdc = 0
    
    if fSdc > 1:
        fSdc = 1

# Check if instruction directly affects output store deterministicaly
for key in cmp_percent:
    if cmp_percent[key] == True:
        if out_store == True:
            fSdc = 1 
            fCrash = 0
            fBenign = 0


# Handling lucky stores
scale = fSdc
for nums in DOMI_INDEX:
    scale = (1 - domi_val[nums])*fSdc

fBenign += (fSdc - scale)
fSdc = scale

print("\n***************************")
print("Final SDC: " + str(fSdc))
print("Final Benign: " + str(fBenign))
print("Final Crash: " + str(fCrash))

#os.chdir("..")
#if os.path.exists("Inst" + str(targetIndex)):
#    rmtree("Inst" + str(targetIndex))