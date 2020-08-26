
import sys,os

sdc_dic = {}
count_dic = {}
sdc_total = 0
count_total = 0

directory = sys.argv[1]

file1 = open(os.path.join(directory, "fi_breakdown.txt"))

for line in file1:
    line1 = line.split(", ")
    inst = line1[0][len("--FI Index: "):]
    inst = int(inst.strip())
    count = int(line.split("Total FI: ")[1])
    count_dic[inst] = count
    line1 = line.split("SDC: ")
    sdc = int(line1[1].split(",")[0])
    sdc_dic[inst] = sdc
    sdc_total += sdc_dic[inst]
    count_total+=count

file1.close()

og_sdc= (100*sdc_total)/float(count_total)

#print og_sdc

for i in range(1,34):
    file_name = os.path.join(directory, "output", "selected_inst_amount_" + str(i) + ".txt")
    proc_list = []
    file1 = open(file_name)
    prot_count = 0
    prot_sdc = 0
    #Get the protexted instructons
    for line in file1:
        proc_list.append(int(line.strip()))
    file1.close()
    for key in proc_list:
        prot_count += count_dic[key]
        prot_sdc += sdc_dic[key]

    prot_sdc = sdc_total - prot_sdc
    
    if prot_count != 0:
        new_sdc = 100*(prot_sdc)/float(count_total)
    else:
        new_sdc = og_sdc

    coverage = (og_sdc - new_sdc)/og_sdc*100
    print(coverage)