import os

PROGRAM_NAME = "particlefilter_naive"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = " -x 128 -y 128 -z 10 -np 1000 "
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 100
CF_STAGE_2_NUM = 100

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [117, 121]
