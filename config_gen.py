X_threads = 64 # Total threads in x dimension in one invocation of kernel
Y_threads = 1 # Total threads in y dimension in one invocation of kernel
Invoc_count = 1 # Total invocations that you are profiling for
start_index = 0 # Start index of loop comparison in kernel
end_index = 0 # End index of loop comparison in kernel

src_list = [] # All the files of of benchmark except PROGRAM_NAME in config.py

SHARED_MEM_USE = True # If kernel does not use shared memory make it False

total_shared_mem_size = 1024 # If kernel does not use shared memory, leave it as it is

domi_list = [] # Index of cmp instruction that dominate output stores
domi_val = [] # Values from results/lucky_stores.txt coresponding to cmp instructions in domi_list