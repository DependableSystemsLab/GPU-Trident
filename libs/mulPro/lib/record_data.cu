#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ unsigned long long mulValue1List[LIST_SIZE];
extern "C" __device__ unsigned long long mulValue2List[LIST_SIZE];
extern "C" __device__ unsigned long long mulCountList[LIST_SIZE];
extern "C" __device__ unsigned long long record_flag;

void bambooLogRecordOff(){

    long long local_record = 0;

    cudaMemcpyToSymbol(record_flag, &local_record, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelBegin(long long i) {

    i = 1;

    cudaMemcpyToSymbol(record_flag, &i, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelEnd() 
{

#ifdef KERNELTRACE
    cudaDeviceSynchronize();
#endif
    
    long long mulValue1ListLocal[LIST_SIZE];
    long long mulValue2ListLocal[LIST_SIZE];
    long long mulCountListLocal[LIST_SIZE];
    
    cudaMemcpyFromSymbol(mulValue1ListLocal, mulValue1List, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(mulValue2ListLocal, mulValue2List, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(mulCountListLocal, mulCountList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    
    FILE *profileFile = fopen("profile_mul_value_result.txt", "w");
    for(long long i=0; i < LIST_SIZE; i++){
        if(mulCountListLocal[i] != 0)
        {
            fprintf(profileFile, "%lld %lld %lld %lld\n", i, mulCountListLocal[i], mulValue1ListLocal[i], mulValue2ListLocal[i]);
        }
    }
    
    fclose(profileFile);
}
