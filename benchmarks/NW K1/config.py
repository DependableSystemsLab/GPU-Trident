import os

PROGRAM_NAME = "needle"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "32 10"
LLVM_PATH = "/home/gpli/llvm-3.0-build"

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [32, 46, 57, 64] #K1
#GLOBAL_LOAD_LIST = [285, 296, 305, 312] #K2

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [244] #K1
#GLOBAL_STORE_LIST = [492] #K1