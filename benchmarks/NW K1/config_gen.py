X_threads = 64
Y_threads = 1
Invoc_count = 1
start_index = 0
end_index = 0
src_list = ["needle_kernel.cu", "needle.h"]

SHARED_MEM_USE = True
DO_REDUCTION = False

total_shared_mem_size = 2.18*1024


domi_list = [233]
domi_val = [0]
