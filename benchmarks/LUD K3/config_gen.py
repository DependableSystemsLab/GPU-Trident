X_threads = 16*3
Y_threads = 16*3
Invoc_count = 3
start_index = 0
end_index = 0
src_list = ["common.c", "common.h", "lud_kernel.cu"]

SHARED_MEM_USE = True

total_shared_mem_size = 2.0480*1000

domi_list = []
domi_val = []
