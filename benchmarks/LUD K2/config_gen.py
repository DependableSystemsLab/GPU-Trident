X_threads = 32*3
Y_threads = 1
Invoc_count = 3
start_index = 0
end_index = 0
src_list = ["common.c", "common.h", "lud_kernel.cu"]

SHARED_MEM_USE = True

total_shared_mem_size = 3.072*1000

domi_list = [324,334,365]
domi_val = [0,0,0]
