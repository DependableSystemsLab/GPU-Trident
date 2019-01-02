
import os,subprocess
targetIndex = 19
src_name = "example.cu"

flagHeader = "CICC_MODIFY_OPT_MODULE=1 LD_PRELOAD=./libnvcc.so nvcc -arch=sm_30 -rdc=true -dc -g -G -Xptxas -O0 -D BAMBOO_PROFILING"
ktraceFlag = " -D KERNELTRACE"
makeCommand1 = "STUPLE_FILE=results/simplified_inst_tuples.txt " + "S_INDEX=" + str(targetIndex) + " " + flagHeader + " " + src_name + " -o temp.o" + ktraceFlag

file_list = os.listdir("/home/abdul/GPU-Trident/GPU-Trident-mem/libs/sim/lib")

os.system("cp /home/abdul/GPU-Trident/GPU-Trident-mem/libs/sim/lib/* .")

print "\n\n\n"

print makeCommand1

print "\n\n\n"
simOutput = subprocess.check_output(makeCommand1, shell=True,stderr=subprocess.STDOUT)

print simOutput

# Clean the copied files
for file in file_list:
    os.remove(file)

# Clean produced file
os.remove("temp.o")
os.remove("opt_bamboo_after.ll")
os.remove("opt_bamboo_before.ll")