import os

PROGRAM_NAME = "needle"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "32 10"
LLVM_PATH = ""

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [285, 296, 305, 312] #K2

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [492] #K1