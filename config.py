import os

PROGRAM_NAME = "example"
PROGRAM_OUTPUT_NAME = "result.txt" 
INPUT_PARAMETERS = ""
LLVM_PATH = ""
EXEC_MODE = 0 # 0 -> Single threaded, 1 -> Multi-threaded

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = []