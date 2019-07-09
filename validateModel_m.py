import sys, os, subprocess

prog_name = sys.argv[1]

totalCount = 0 
accumSdc = 0
accumBenign = 0
accumCrash = 0

index = []
count = []
processes = []

with open("results/fi_breakdown.txt", 'r') as rf:
    lines = rf.readlines()
    for line in lines:
        if "--" in line:
            index.append(int(line.split("FI Index: ")[1].split(",")[0]))
            count.append(int(line.split("Total FI: ")[1].replace("\n", "")))
            totalCount += count[-1]

for inst in index:
    command = ["python", "executeModel_m.py", prog_name, `inst`]
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    processes.append(p)

counter = 0

for counter in range(len(processes)):
    processes[counter].wait()
    diffLines = processes[counter].stdout.read()

    crashR = float(diffLines.split("\n")[-2].split(": ")[1].replace("\n", ""))
    maskingR = float(diffLines.split("\n")[-3].split(": ")[1].replace("\n", ""))
    sdcR = float(diffLines.split("\n")[-4].split(": ")[1].replace("\n", ""))

    accumSdc += sdcR * count[counter]
    accumBenign += maskingR * count[counter]
    accumCrash += crashR * count[counter]

    print "FI index: " + `index[counter]` + ", SDC: " + `sdcR` + ", Benign: " + `maskingR` + ", Crash: " + `crashR`
    counter+=1;

print "Aggregated SDC: " + ` accumSdc/ float(totalCount)` 
print "Aggregated Benign: " + `accumBenign / float(totalCount)` 
print "Aggregated Crash: " + `accumCrash / float(totalCount)` 
