#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

void bambooLogKernelBegin() {

}

void bambooLogKernelEnd() {

#ifdef KERNELTRACE
	cudaDeviceSynchronize();
#endif
}
