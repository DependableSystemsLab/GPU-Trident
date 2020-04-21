import os

PROGRAM_NAME = "" # Name of main CUDA source file, without extension
PROGRAM_OUTPUT_NAME = "" # Name of output file produced by application (if any) 
INPUT_PARAMETERS = "" # Input for applications
LLVM_PATH = "" # Install path of llvm
EXEC_MODE = 0 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 1000
CF_STAGE_2_NUM = 1000

# Loads that transfer data from global memory to shared memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = []