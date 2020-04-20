
import sys
from config_gen import X_threads, Y_threads, Invoc_count, start_index

hash_table = [[[set() for x in range(X_threads)] for y in range(Y_threads)]for z in range(Invoc_count)]

if sys.argv[1] == "True":
    file1 =  open("results/control_flow_group-1.txt")

    #file1 = open("partial.txt")
    num = 0
    num_temp = ""

    first = True
    path_string = ""

    unique_strings = []

    for line in file1:
        if line.strip() == "":
            continue
    
        line1 = line.split(':')[0]
        line1 = line1.split(" ")

        call_count = int(line1[0])
        
        x = int(line1[1])
        y = int(line1[2])
    
        line = line.split(':')[1].strip()

        if line == "":
            continue
        first = True
        
        for char in line:
            #print char
            if char == 'T' or char == 'F':

                if len(num_temp) == 0:
                    continue
                num = int(num_temp)
                num_temp = ""

                if num == start_index:
                    #print "Start index excountered"
                    if first == True:
                        first = False
                        path_string += (str(num) + char) 
                    else:
                        if path_string not in unique_strings:
                            unique_strings.append(path_string)

                        index = unique_strings.index(path_string)
                
                        hash_table[call_count][y][x].add(index)
                
                        path_string = (str(num) + char) 
                else:
                    path_string += (str(num) + char) 
            else:
                num_temp += char

    file1.close()

file1 =  open("results/control_flow_group-2.txt")

file2 =  open("results/control_flow_group.txt", "w")

for line in file1:
    if line.strip() == "":
        continue

    #print "Line", line
    line1 = line.split(':')[0]
    line1 = line1.split(" ")

    call_count = int(line1[0])
    x = int(line1[1])
    y = int(line1[2])
    #print call_count, x
    line = line.split(':')[1].strip()

    if line == "":
        continue

    temp_list = sorted(list(hash_table[call_count][y][x]))

    line += '-'

    for num in temp_list:
         line = line + str(num)
    
    line_t = str(call_count) + " " + str(x) + " " + str(y) + ":" + str(line) + "\n"
    
    file2.write(line_t)

file1.close()
file2.close()

file1 =  open("results/control_flow_group.txt")


group_dic = {}

for line in file1:
    if line.strip() == "":
        continue

    #print "Line", line
    line1 = line.split(':')[0]
    line1 = line1.split(" ")

    call_count = int(line1[0])
    x = int(line1[1])
    y = int(line1[2])
    #print call_count, x
    key = line.split(':')[1].strip()

    if line == "":
        continue

    if key not in group_dic:
        group_dic[key] = []
    
    thread_tuple = (call_count, x , y)
    group_dic[key].append(thread_tuple)

file1.close()

for key in group_dic:
    print(group_dic[key][0])