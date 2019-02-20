import math

shared_mem_used = 256

#shared memory is 48 KB
total_shared_mem_size = 48*1024 

#Total global memory
total_memory = 2*1024*1024

vmsize = shared_mem_used
benignBits = math.floor(math.log(total_shared_mem_size, 2))
dataWidth = 64

shared_crashRate = (dataWidth - benignBits) / float(dataWidth)

benignBits = math.floor(math.log(total_memory, 2))

global_crashRate = (dataWidth - benignBits) / float(dataWidth)

f = open('readable_indexed.ll')

index = 0
for line in f:
    if ("call void @profileCount(i64 " in line):
        index = str(line[len("  call void @profileCount(i64 "):-2])
    
    if ("  store " in line):
        if "addrspace(3)" in line:
            print index + " " +str(shared_crashRate - 0.1)
        else:
            print index + " " + str(global_crashRate - 0.1)
    
    if ("= load " in line):
        if "addrspace(3)" in line:
            print index + " " + str(shared_crashRate - 0.1)
        else:
            print index + " " + str(global_crashRate - 0.1)
