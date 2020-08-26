import sys, os, subprocess


###############################
goldenFiBD = sys.argv[1]
modelFiBD = sys.argv[2]
outputFileFolder = sys.argv[3]
###############################
numOfPoints = 33
totalFiCount = 0
instSdcDic = {}
instCountDic = {}
mInstSdcDic = {}

with open(goldenFiBD, 'r') as gfbd:
    lines = gfbd.readlines()
    for line in lines:
        if "-- FI Index:" in line:
            fiCount = int(line.split("Total FI: ")[1].replace("\n", "")) # Proportional to its footprint
            totalFiCount += fiCount
            instIndex = int(line.split(",")[0].replace("-- FI Index: ", ""))
            sdcRate = float(line.split(",")[1].replace(" SDC: ", ""))
            instSdcDic[instIndex] = sdcRate
            instCountDic[instIndex] = fiCount

with open(modelFiBD, 'r') as mfbd:
    lines = mfbd.readlines()
    for line in lines:
        if "FI index: " in line:
            instIndex = int(line.split(", ")[0].replace("FI index: ", ""))
            sdcRate = float(line.split(", ")[1].replace("SDC: ", ""))
            mInstSdcDic[instIndex] = sdcRate

#"knapsack.py 1-2,2-5,3-10 12"
pairString = ""
totalCoverage = 0
totalTrueCoverage = 0
kpPosDic = {}
kpIndexDic = {}
kpIndex = 0
for instIndex in instSdcDic:
    fiCount = instCountDic[instIndex]
    sdcRate = instSdcDic[instIndex]/float(fiCount) # Use model sdc rate for knapsack
    #print "SDC rate:", sdcRate
    #print "FI count:", fiCount
    sdcContr = int( sdcRate * fiCount / float(totalFiCount) * 10000 ) # scaled by 10000
    if sdcContr == 0:
        sdcContr = 1
    totalCoverage += sdcContr

    # This is used to get true sdc contribution by kp index
    kpPosDic[kpIndex] = int( instSdcDic[instIndex] * fiCount / float(totalFiCount) * 10000 )
    kpIndexDic[kpIndex] = instIndex
    totalTrueCoverage += kpPosDic[kpIndex]
    kpIndex += 1

    if pairString == "":
        pairString += `fiCount` + "-" + `sdcContr`
    else:
        pairString += "," + `fiCount` + "-" + `sdcContr`


maxCost = 0
counter = 0
#print "Total FI", totalFiCount
#print pairString

for x in range(0, numOfPoints):
    #print x
    counter+=1
    maxCost += totalFiCount / numOfPoints
    #print maxCost
    command = ["python", "knapsack.py", pairString, `maxCost`]
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    ksOutput = p.stdout.read()
    #print ksOutput
    #exit()
    # static inst put in knapsack
    instList = ksOutput.split("\n")[1].split(" ")
    trueProfit = 0
    #print(os.path.join(outputFileFolder, ("selected_inst_amount_" + str(counter) + ".txt")))
    # Write to file for all inst required protection
    with open(os.path.join(outputFileFolder, ("selected_inst_amount_" + str(counter) + ".txt")), 'w') as of:
        for kpIndex in instList:
            if kpIndex == '':
                continue
            trueSdcContr = kpPosDic[int(kpIndex)]       
            trueProfit += trueSdcContr 
            instIndex = kpIndexDic[int(kpIndex)]
            of.write(`instIndex` + "\n")
 
    w = int(ksOutput.split("\n")[0].split(",")[0].replace("W: ", "")) # current weight (# of inst)
    wp = w / float(totalFiCount)
#   p = int(ksOutput.split("\n")[0].split(",")[1].replace("P: ", "")) # current profit (fault coverage)
#   pp = p / float(totalCoverage)
    pp = trueProfit / float(totalTrueCoverage)

    #print pp # % of inst protected -> % of true sdc coverage 


