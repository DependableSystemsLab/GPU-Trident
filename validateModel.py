import sys, os, subprocess

prog_name = sys.argv[1]

totalCount = 0 
accumSdc = 0
accumBenign = 0
accumCrash = 0
with open("results/fi_breakdown.txt", 'r') as rf:
    lines = rf.readlines()
    for line in lines:
        if "--" in line:
            index = int(line.split("FI Index: ")[1].split(",")[0])
            count = int(line.split("Total FI: ")[1].replace("\n", ""))
            totalCount += count

            command = ["python", "executeModel.py", prog_name, str(index)]
            p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            diffLines = p.stdout.read()
            diffLines = diffLines.decode("utf-8")
            
            crashR = float(diffLines.split("\n")[-2].split(": ")[1].replace("\n", ""))
            maskingR = float(diffLines.split("\n")[-3].split(": ")[1].replace("\n", ""))
            sdcR = float(diffLines.split("\n")[-4].split(": ")[1].replace("\n", ""))

            accumSdc += sdcR * count
            accumBenign += maskingR * count
            accumCrash += crashR * count

            print("FI index: " + str(index) + ", SDC: " + str(sdcR) + ", Benign: " + str(maskingR) + ", Crash: " + str(crashR))

print("Aggregated SDC: " + str(accumSdc/ float(totalCount)))
print("Aggregated Benign: " + str(accumBenign / float(totalCount))) 
print("Aggregated Crash: " + str(accumCrash / float(totalCount))) 