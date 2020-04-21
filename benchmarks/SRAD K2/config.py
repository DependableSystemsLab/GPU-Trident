import os

PROGRAM_NAME = "srad"
PROGRAM_OUTPUT_NAME = "" 
INPUT_PARAMETERS = "128 128 0 31 0 31 0.5 2"
LLVM_PATH = ""

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [539, 545, 565, 572, 593, 600, 668, 671, 675, 679] #K2

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [702] #K2
