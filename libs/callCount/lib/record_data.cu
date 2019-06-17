#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ long long callCountList[LIST_SIZE];

void bambooLogKernelBegin() {

}

void bambooLogRecordOff() {

}

void bambooLogKernelEnd() {

#ifdef KERNELTRACE
    cudaDeviceSynchronize();
#endif
    
    long long resultArray[LIST_SIZE] = {0};
    cudaMemcpyFromSymbol(&resultArray, callCountList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);    
    
    FILE *profileFile = fopen("profile_call_prob_result.txt", "w");
    for(long long i=0; i<LIST_SIZE; i++){
        if(resultArray[i] != 0){
            fprintf(profileFile, "%lld: %lld\n", i, resultArray[i]);
        }
    }
    fclose(profileFile);
}
