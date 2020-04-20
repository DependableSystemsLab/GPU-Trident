X_threads = 64
Y_threads = 1
Invoc_count = 1
start_index = 0
end_index = 0
src_list = ["kernel.cu", "kernel2.cu"]

SHARED_MEM_USE = False
DO_REDUCTION = False

total_shared_mem_size = 1*1024

domi_list = [51, 55]
domi_val = [0.25, 0.25]
