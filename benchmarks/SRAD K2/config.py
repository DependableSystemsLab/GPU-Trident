import os

PROGRAM_NAME = "srad"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "128 128 0 31 0 31 0.5 2"
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 100
CF_STAGE_2_NUM = 100

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [539, 545, 565, 572, 593, 600, 668, 671, 675, 679] #K2

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [702] #K2
