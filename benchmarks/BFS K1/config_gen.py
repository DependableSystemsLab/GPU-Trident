X_threads = 64
Y_threads = 1
Invoc_count = 1
start_index = 0
end_index = 0
src_list = ["kernel.cu", "kernel2.cu"]

SHARED_MEM_USE = False

total_shared_mem_size = 1*1024

domi_list = [5, 9, 25, 32]
domi_val = [0.33, 0.33, 0, 0]
