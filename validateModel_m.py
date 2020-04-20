import sys, os, subprocess

prog_name = sys.argv[1]

totalCount = 0 
accumSdc = 0
accumBenign = 0
accumCrash = 0
step = 100

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

index_sublist_set = []
count_sublist_set = []

#Break the list into equal parts
for i in range(0, len(index), step):
    end = step
    if len(index[i:]) < step:
        end = len(index[i:])
    index_sublist_set.append(index[i:i+end])
    count_sublist_set.append(count[i:i+end])

for subgroup in range(len(index_sublist_set)):

    for inst in index_sublist_set[subgroup]:
        command = ["python", "executeModel.py", prog_name, str(inst)]
        p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        processes.append(p)
    counter = 0

    for counter in range(len(processes)):
        processes[counter].wait()
        diffLines = processes[counter].stdout.read()
        diffLines = diffLines.decode("utf-8")
        crashR = float(diffLines.split("\n")[-2].split(": ")[1].replace("\n", ""))
        maskingR = float(diffLines.split("\n")[-3].split(": ")[1].replace("\n", ""))
        sdcR = float(diffLines.split("\n")[-4].split(": ")[1].replace("\n", ""))

        accumSdc += sdcR * count_sublist_set[subgroup][counter]
        accumBenign += maskingR * count_sublist_set[subgroup][counter]
        accumCrash += crashR * count_sublist_set[subgroup][counter]

        print("FI index: " + str(index_sublist_set[subgroup][counter]) + ", SDC: " + str(sdcR) + ", Benign: " + str(maskingR) + ", Crash: " + str(crashR))
        counter+=1;

    del processes[:]

print("Aggregated SDC: " + str(accumSdc/ float(totalCount)))
print("Aggregated Benign: " + str(accumBenign / float(totalCount))) 
print("Aggregated Crash: " + str(accumCrash / float(totalCount)))  
