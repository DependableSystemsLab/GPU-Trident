import os

PROGRAM_NAME = "particlefilter_naive"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = " -x 128 -y 128 -z 10 -np 1000 "
LLVM_PATH = ""

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [117, 121]
