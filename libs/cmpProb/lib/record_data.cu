#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ unsigned long long zeroList[LIST_SIZE];
extern "C" __device__ unsigned long long oneList[LIST_SIZE];
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

    unsigned long long zero_result[LIST_SIZE] = {0};
    unsigned long long one_result[LIST_SIZE] = {0};
    
    cudaMemcpyFromSymbol(zero_result, zeroList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(one_result, oneList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    
    FILE *profileFile = fopen("profile_cmp_prob_result.txt", "w");
    for(long long i=0; i < LIST_SIZE; i++){
        if(zero_result[i] != 0 || one_result[i] != 0){
            fprintf(profileFile, "%lld: %lld %lld\n", i, zero_result[i], one_result[i]);
        }
    }
    
    fclose(profileFile);
}
