#! /usr/bin/python

import os, sys

#####################################
irPath = sys.argv[1]
#####################################

tuplePropDic = {}
tupleMaskingDic = {}
tupleCrashDic = {}
shiftAvDic = {}


# Read cmp_masking.txt
with open("results/cmp_masking.txt", "r") as cf:
    cmpLines = cf.readlines()
    for cmpLine in cmpLines:
        llfiIndex = int(cmpLine.split(" ")[0])
        maskingRate = float(cmpLine.split(" ")[1].replace("\n", ""))
        # We assume cmp does not cause crash
        propRate = 1-maskingRate
        tuplePropDic[llfiIndex] = propRate
        tupleMaskingDic[llfiIndex] = maskingRate
        tupleCrashDic[llfiIndex] = 0

# Read crash_rate.txt
with open("results/crash_rate.txt", "r") as rf:
    crashLines = rf.readlines()
    for crashLine in crashLines:
        llfiIndex = int(crashLine.split(" ")[0])
        crashRate = float(crashLine.split(" ")[1].replace("\n", ""))
        # We assume load/store has no masking in tuple - though stores have masking factor in mem dep. modeling.
        maskingRate = float(crashLine.split(" ")[2].replace("\n", ""))
        propRate = float(crashLine.split(" ")[3].replace("\n", ""))
        tuplePropDic[llfiIndex] = propRate
        tupleMaskingDic[llfiIndex] = maskingRate
        tupleCrashDic[llfiIndex] = crashRate

# Read profile_shift_value_result.txt
with open("results/profile_shift_value_result.txt", 'r') as psf:
    shiftLines = psf.readlines()
    for shiftLine in shiftLines:
        llfiIndex = int(shiftLine.split(": ")[0])
        aV = int(shiftLine.split(": ")[1].split(" ")[0])
        shiftAvDic[llfiIndex] = aV

# Read profile_shift_value_result.txt
with open("results/profile_mul_value_result.txt", 'r') as psf:
    mulLines = psf.readlines()
    for mulLine in mulLines:
        llfiIndex = int(mulLine.split(" ")[0])
        totalCount = int(mulLine.split(" ")[1])
        zeroProb1 = 0.5*int(mulLine.split(" ")[2])/float(totalCount)
        zeroProb2 = 0.5*int(mulLine.split(" ")[3])/float(totalCount)
        tuplePropDic[llfiIndex] = 1 - zeroProb1 - zeroProb2
        tupleMaskingDic[llfiIndex] = zeroProb1 + zeroProb2
        tupleCrashDic[llfiIndex] = 0

next_inst_present = True
llfiIndex = 0
# Read llfi indexed IR for the rest of insts        
with open(irPath, 'r') as irf:
    irLines = irf.readlines()
    for irLine in irLines:
        if next_inst_present == True:
            next_inst_present = False
            if llfiIndex not in tuplePropDic:
                propRate = 1
                crashRate = 0
                maskingRate = 0
                # For 'and', 'trunc', 'shl', 'lshr'
                if " and " in irLine: # From where do we get these numbers
                    propRate = 0.1
                    maskingRate = 0.9
                if ' trunc ' in irLine: # We find the probability that the effected instruction was discarded
                    # tmp36 = trunc i64 %tmp35 to i32    !llfi_index ...
                    type1 = int(irLine.split(" trunc ")[1].split(" ")[0].replace("i", ""))
                    type2 = int(irLine.split(" trunc ")[1].split(" ")[3].replace("i", "").replace(",", ""))
                    maskingRate = (type1-type2)/float(type1)
                    propRate = 1 - maskingRate
                if llfiIndex in shiftAvDic: 
                    # Only get the one for executed
                    totalWidth = 0
                    irLine = irLine.replace("nuw ", "").replace("nsw ", "")
                    if ' shl ' in irLine:    # We find the probability that if the corrupted bit was shifted out
                        # %32 = shl i32 1, %18, !llfi_index !1423
                        # %98 = shl nsw i64 %97, 4, !llfi_index !950
                        if "i" in irLine.split(" shl ")[1].split(" ")[0]:
                            totalWidth = int(irLine.split(" shl ")[1].split(" ")[0].replace("i", ""))
                        else:
                            totalWidth = int(irLine.split(" shl ")[1].split(" ")[1].replace("i", ""))
                        shiftWidth = shiftAvDic[llfiIndex]
                        maskingRate = shiftWidth*2 / float(totalWidth) # Why multiply by 2
                        propRate = 1 - maskingRate
                    if ' lshr ' in irLine:
                        # %26 = lshr i32 %24, %25, !llfi_index !1416
                        if "i" in irLine.split(" lshr ")[1].split(" ")[0]:
                            totalWidth = int(irLine.split(" lshr ")[1].split(" ")[0].replace("i", ""))
                        else:
                            totalWidth = int(irLine.split(" lshr ")[1].split(" ")[1].replace("i", ""))
                        shiftWidth = shiftAvDic[llfiIndex]
                        maskingRate = shiftWidth / float(totalWidth)
                        propRate = 1 - maskingRate
                    if ' ashr ' in irLine:
                        # %28 = ashr i32 %pat2.0.lcssa, %width, !llfi_index !754
                        if "i" in irLine.split(" ashr ")[1].split(" ")[0]:
                            totalWidth = int(irLine.split(" ashr ")[1].split(" ")[0].replace("i", ""))
                        else:
                            totalWidth = int(irLine.split(" ashr ")[1].split(" ")[1].replace("i", ""))
                        shiftWidth = shiftAvDic[llfiIndex]
                        maskingRate = (shiftWidth*2-1) / float(totalWidth) # From where does this come
                        propRate = 1 - maskingRate
                if ' fadd double ' in irLine:
                    propRate = 0.75
                    maskingRate = 0.25
 
                # Assume the rest insts have prop rate of 1
                tuplePropDic[llfiIndex] = propRate
                tupleMaskingDic[llfiIndex] = maskingRate
                tupleCrashDic[llfiIndex] = crashRate
            
        if "call void @profileCount" in irLine:
            #llfiIndex = int(irLine.split("!llfi_index !")[1].replace("\n", ""))
            llfiIndex = int(irLine[len("  call void @profileCount(i64 "):-2])
            next_inst_present = True
                

# Write to inst_tuples.txt
os.system("rm results/inst_tuples.txt")


with open("results/inst_tuples_1.txt", "w") as wf:
    for index in sorted(tuplePropDic.keys()):
        wf.write(str(index) + " <" + str(tuplePropDic[index]) + "," + str(tupleMaskingDic[index]) + "," + str(tupleCrashDic[index]) + ">\n")


k_range = open("kernel_range.txt", 'r')


k_range_lines = []

for line in k_range:
    k_range_lines.append(int(line))

k_range.close()

inst_tuple_file = open("results/inst_tuples_1.txt")

new_file = ""

for line in inst_tuple_file:
    if k_range_lines[0] <= int(line.split()[0]) <= k_range_lines[1]:
        new_file += line

wf = open("results/inst_tuples.txt", 'w')

wf.write(new_file)

wf.close()

os.system("rm results/inst_tuples_1.txt")