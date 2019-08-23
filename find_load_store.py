import math
from config_gen import total_shared_mem_size

#Total global memory
total_memory = 64

benignBits = math.floor(math.log(total_shared_mem_size - 1, 2))
dataWidth = 32

shared_crashRate = ((dataWidth - benignBits) / float(dataWidth))*0.5

benignBits = math.floor(math.log(total_memory - 1, 2))
dataWidth = 64

global_crashRate = (dataWidth - benignBits) / float(dataWidth)

global_crashRate = 0.75
#shared_crashRate = 0.65

kernel_list = []
new_kernel = 0
looking_for_end = 0
start_index = 0
end_index = 0
kernel_number = 0;


# Get the first and last instruction index of kernels
f = open('readable_indexed.ll')

for line in f:
    if "define void " in line:
        new_kernel = 1
    
    if "call void @profileCount" in line and new_kernel == 1:
        start_index = str(line[len("  call void @profileCount(i64 "):-2])
        new_kernel = 2
    
    if "call void @profileCount" in line and new_kernel == 2:
        end_index = str(line[len("  call void @profileCount(i64 "):-2])

    if "ret void" in line:
        kernel_indices = [int(start_index), int(end_index)]
        kernel_list.append(kernel_indices)

f.close()

# Check which kernels is under test
f = open("results/instCountResult.txt")

for line in f:
    region = int(line.split()[0][:-1])
    break

for pair in kernel_list:
    if region in range(pair[0], pair[1]):  
        break
    kernel_number+=1

f.close()

rec_action = False
flip = False

f = open('readable_indexed.ll')

index = 0

f_shared = open("shared_mem.txt", 'w')

for line in f:
    if rec_action == True:
        flip = True
        
    if ("call void @profileCount(i64 " in line):
        index = str(line[len("  call void @profileCount(i64 "):-2])
        if int(index) in range(kernel_list[kernel_number][0], kernel_list[kernel_number][1]):
            #print "REC action" + str(index)
            rec_action = True
            flip = False
            
    
    if ("  store " in line) and rec_action == True:
        rec_action = False
        if "addrspace(3)" in line:
            print index + " " + str(shared_crashRate) + " " + str(0.5) + " " + str(0.5 - shared_crashRate)
            f_shared.write(str(index) + ' S\n')
        else:
            print index + " " + str(global_crashRate) + " " + str(0.0) + " " + str(1.0 - global_crashRate)
    
    if ("= load " in line) and rec_action == True:
        rec_action = False
        if "addrspace(3)" in line:
            print index + " " + str(shared_crashRate)  + " " + str(0.5) + " " + str(0.5 - shared_crashRate)
            f_shared.write(str(index) + ' L\n')
        else:
            print index + " " + str(global_crashRate) + " " + str(0.0) + " " + str(1.0 - global_crashRate)
    
    if flip == True:
        rec_action = False
    

f.close()
f_shared.close()

f = open("kernel_range.txt", 'w+')

for num in kernel_list[kernel_number]:
    f.write(str(num) + '\n')

f.close()
