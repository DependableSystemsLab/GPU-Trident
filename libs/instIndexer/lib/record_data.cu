#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ long long instCountList[LIST_SIZE];

void bambooLogRecordOff(){

}

void bambooLogKernelBegin(int i) {

}

void bambooLogKernelEnd() {

#ifdef KERNELTRACE
	cudaDeviceSynchronize();
#endif
	
}
