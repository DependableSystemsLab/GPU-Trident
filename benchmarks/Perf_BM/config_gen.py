X_threads = 8*1024
Y_threads = 1
Invoc_count = 1000
start_index = 0
end_index = 0
src_list = ["CudaBenchmarkingCode.cu"]

SHARED_MEM_USE = False
DO_REDUCTION = True

total_shared_mem_size = 2.18*1024

domi_list = [6]
domi_val = [0.125]
