import os

PROGRAM_NAME = "lud"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "-i 64.dat"
LLVM_PATH = "/home/gpli/llvm-3.0-build"

# Loads that transfer data from global memory
#GLOBAL_LOAD_LIST = [395, 412] #K3
#GLOBAL_LOAD_LIST = [156, 180, 203, 226]
GLOBAL_LOAD_LIST = [13] #K1

# Stores that transfer data to global memory
#GLOBAL_STORE_LIST = [455] #K3
#GLOBAL_STORE_LIST = [347, 373]
GLOBAL_STORE_LIST = [137] #K1