import os

PROGRAM_NAME = "hotspot"
PROGRAM_OUTPUT_NAME = "output" 
INPUT_PARAMETERS = "512 2 2 temp_512 power_512 output"
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [48,54]

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [257]
