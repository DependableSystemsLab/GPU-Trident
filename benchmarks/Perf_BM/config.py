import os

PROGRAM_NAME = "CudaBenchmarkingCode"
PROGRAM_OUTPUT_NAME = ""
INPUT_PARAMETERS = ""
LLVM_PATH = ""

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [] #K1

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [14] #K1