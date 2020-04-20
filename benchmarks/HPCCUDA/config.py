import os

PROGRAM_NAME = "blur"
PROGRAM_OUTPUT_NAME = ""
INPUT_PARAMETERS = ""
LLVM_PATH = ""

# Loads that transfer data from global memory
GLOBAL_LOAD_LIST = []

# Stores that transfer data to global memory
GLOBAL_STORE_LIST = [58,72,86,108,119,130,152,163,174,196,207,218,240,251,262,277,285,293,308,316,324,339,347,355,370,378,386] #K1