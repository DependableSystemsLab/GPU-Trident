import os

PROGRAM_NAME = "bfs"
PROGRAM_OUTPUT_NAME = "result.txt" 
INPUT_PARAMETERS = "graph4096.txt"
LLVM_PATH = ""

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [58, 60, 61, 63]