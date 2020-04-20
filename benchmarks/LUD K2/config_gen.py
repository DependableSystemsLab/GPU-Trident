X_threads = 64
Y_threads = 1
Invoc_count = 1
start_index = 0
end_index = 0
src_list = ["common.c", "common.h", "lud_kernel.cu"]

SHARED_MEM_USE = True
DO_REDUCTION = False

total_shared_mem_size = 3.072*1000

domi_list = [324,334,365]
domi_val = [0,0,0]
