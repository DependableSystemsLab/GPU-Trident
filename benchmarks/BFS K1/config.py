import os

PROGRAM_NAME = "bfs"
PROGRAM_OUTPUT_NAME = "result.txt" 
INPUT_PARAMETERS = "graph4096.txt"
LLVM_PATH = ""
EXEC_MODE = 1 # 0 -> Single threaded, 1 -> Multi-threaded

CF_STAGE_1_NUM = 100
CF_STAGE_2_NUM = 100

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [12, 38, 40]