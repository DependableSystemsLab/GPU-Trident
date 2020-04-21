# GPU-Trident
GPU-Trident analytically models error propagation in CUDA kernels and predicts the SDC probability of these kernels and their instructions. It consists of LLVM compiler passes and python scripts. 

# Prerequisites
Dependencies (Tested on Ubuntu 14.04.6 LTS)
1. Python 2.7 or higher
2. NVCC v6.0.1
3. LLVM 3.0

# Preparation
1. Add path to NVCC binaries to your system path and update the build path of LLVM (LLVM_PATH) in `config.py`.
2. Add the header #include `"record_data.cu"` in your benchmark file.
3. Anotate the kernels with `bambooLogKernelBegin()` before every call of your kernel, `bambooLogRecordOff()` after every kernel call of your kernel and `bambooLogKernelEnd()` after all invocation of that particular kernel. `bambooLogKernelBegin()` takes its dynamic call count as its input. Examples of annotation can be seen in example applications in `./benchmarks` directory.

# Execution
1.  Populate the `config.py` and `config_gen.py` files according to kernel properties.
2.  Run `python prepare.py index` command to get the `readable_indexed.ll` file. Use this file to get the index of output stores for this kernel and update the `config.py` file.
3.  Run `python prepare.py profile` and populate `domi_val` in `config.py`, using `./results/lucky_store_details.txt` file.
4.  Run `python prepare.py execute` to get the overall SDC percentage and instruction SDC percentage predictions in `./results/prediction.results` file after command completion.