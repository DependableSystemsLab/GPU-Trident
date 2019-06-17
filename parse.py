file1 =  open("results/control_flow_group-1.txt")

#file1 = open("partial.txt")
num = 0
num_temp = ""

#unique_strings = set()
start_index = 168
num_x = 12*8
num_y = 12*8
kernel_invok = 461

first = True
path_string = ""

hash_table = [[[set() for x in range(num_x)] for y in range(num_y)]for z in range(kernel_invok)]
unique_strings = []

for line in file1:
    if line.strip() == "":
        continue

    if line.count(":") != 1:
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
                    path_string += (`num` + char) 
                else:
                    #print "Not first"
                    #print path_string
                    if path_string not in unique_strings:
                        unique_strings.append(path_string)

                    index = unique_strings.index(path_string)
                    #print call_count, x
                    hash_table[call_count][y][x].add(index)
                    #unique_strings.add(path_string)
                    path_string = (`num` + char) 
            else:
                path_string += (`num` + char) 
        else:
            num_temp += char

file1.close()

file1 =  open("results/control_flow_group-2.txt")

file2 =  open("results/control_flow_group.txt", "w")

for line in file1:
    if line.strip() == "":
        continue

    if line.count(":") != 1:
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

    #print call_count, y, x
    temp_list = sorted(list(hash_table[call_count][y][x]))

    line += '-'

    for num in temp_list:
         line = line + `num`
    
    line_t = `call_count` + " " + `x` + " " + `y` + ":" + line + "\n"
    
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
    print group_dic[key][0]
