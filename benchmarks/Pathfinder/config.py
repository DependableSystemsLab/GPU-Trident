import os

PROGRAM_NAME = "pathfinder"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "100000 100 20"
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 200
CF_STAGE_2_NUM = 200

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [54]

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [130]
