import os

PROGRAM_NAME = "srad"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "128 128 0 31 0 31 0.5 2"
LLVM_PATH = ""

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [40, 46, 56, 77, 85, 91, 103, 125, 133]

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [502, 504, 506, 508, 510]
