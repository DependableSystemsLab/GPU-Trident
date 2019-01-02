#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ unsigned long long shiftCount[LIST_SIZE];
extern "C" __device__ unsigned long long shiftVal[LIST_SIZE];

void bambooLogKernelBegin() {

}

void bambooLogKernelEnd()
{

#ifdef KERNELTRACE
	cudaDeviceSynchronize();
#endif

	unsigned long long shift_count[LIST_SIZE] = {0};
	unsigned long long shift_val[LIST_SIZE] = {0};
	
	cudaMemcpyFromSymbol(&shift_count, shiftCount, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
	cudaMemcpyFromSymbol(&shift_val, shiftVal, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    
	FILE *profileFile = fopen("profile_shift_value_result.txt", "w");
	
	for(long long i=0; i < LIST_SIZE; i++){
        
        if(shift_count[i] != 0){
		    fprintf(profileFile, "%lld: %lld %lld\n", i, shift_val[i]/shift_count[i], shift_count[i]);
		}
	}
				
	fclose(profileFile);
	memset(shift_count, 0, sizeof(shift_count));
	memset(shift_val, 0, sizeof(shift_val));
	cudaMemcpyToSymbol(shiftCount, &shift_count, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(shiftVal, &shift_val, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
}