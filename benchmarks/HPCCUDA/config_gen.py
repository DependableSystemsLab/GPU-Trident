X_threads = 16*33
Y_threads = 32*14
Invoc_count = 1
start_index = 0
end_index = 0
src_list = ["blur.cu"]

SHARED_MEM_USE = False
DO_REDUCTION = True

total_shared_mem_size = 1024

domi_list = [25, 27,31,33,37,41,88,90,94,132,176,178,182,220,222,226,264,266,295,297]
domi_val = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
