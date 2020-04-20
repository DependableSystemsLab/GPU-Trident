import os

PROGRAM_NAME = "gaussian"
PROGRAM_OUTPUT_NAME = ""
INPUT_PARAMETERS = "matrix16.txt"
LLVM_PATH = "/home/gpli/llvm-3.0-build"

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = [] #K1

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [70, 88]