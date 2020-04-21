import os

PROGRAM_NAME = "gaussian"
PROGRAM_OUTPUT_NAME = ""
INPUT_PARAMETERS = "matrix16.txt"
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [70, 88]