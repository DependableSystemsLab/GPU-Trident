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
extern "C" __device__ unsigned long long record_flag;

void bambooLogRecordOff(){

    long long local_record = 0;

    cudaMemcpyToSymbol(record_flag, &local_record, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelBegin(long long i) {

    i = 1;

    cudaMemcpyToSymbol(record_flag, &i, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelEnd() {

#ifdef KERNELTRACE
	cudaDeviceSynchronize();
#endif
	
	long long resultArray[LIST_SIZE] = {0};
	cudaMemcpyFromSymbol(&resultArray, instCountList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);    
    
	FILE *profileFile = fopen("instCountResult.txt", "w");
	for(long long i=0; i<LIST_SIZE; i++){
		if(resultArray[i] != 0){
			fprintf(profileFile, "%lld: %lld\n", i, resultArray[i]);
		}
	}
	fclose(profileFile);
	memset(resultArray, 0, sizeof(resultArray));
	cudaMemcpyToSymbol(instCountList, &resultArray, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
}
