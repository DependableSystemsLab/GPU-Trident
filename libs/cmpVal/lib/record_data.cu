#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 10000
extern "C" __device__ unsigned long long icmpValue1List[LIST_SIZE];
extern "C" __device__ unsigned long long icmpValue2List[LIST_SIZE];
extern "C" __device__ double fcmpValue1List[LIST_SIZE];
extern "C" __device__ double fcmpValue2List[LIST_SIZE];
extern "C" __device__ unsigned long long icmpCountList[LIST_SIZE];
extern "C" __device__ unsigned long long fcmpCountList[LIST_SIZE];
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
    
    long long icmpValue1ListLocal[LIST_SIZE];
    long long icmpValue2ListLocal[LIST_SIZE];
    double fcmpValue1ListLocal[LIST_SIZE];
    double fcmpValue2ListLocal[LIST_SIZE];
    long long icmpCountListLocal[LIST_SIZE];
    long long fcmpCountListLocal[LIST_SIZE];
    
    cudaMemcpyFromSymbol(icmpValue1ListLocal, icmpValue1List, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(icmpValue2ListLocal, icmpValue2List, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(fcmpValue1ListLocal, fcmpValue1List, LIST_SIZE * sizeof(double), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(fcmpValue2ListLocal, fcmpValue2List, LIST_SIZE * sizeof(double), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(icmpCountListLocal, icmpCountList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    cudaMemcpyFromSymbol(fcmpCountListLocal, fcmpCountList, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    
    FILE *profileFile = fopen("profile_cmp_value_result.txt", "w");
    for(long long i=0; i < LIST_SIZE; i++){
        if(icmpCountListLocal[i] != 0)
        {
            fprintf(profileFile, "icmp %lld: %lld %lld %lld\n", i, icmpValue1ListLocal[i]/icmpCountListLocal[i], icmpValue2ListLocal[i]/icmpCountListLocal[i], icmpCountListLocal[i]);
        }
        else if(fcmpCountListLocal[i] != 0)
        {
            fprintf(profileFile, "fcmp %lld: %f %f %lld\n", i, fcmpValue1ListLocal[i]/fcmpCountListLocal[i], fcmpValue2ListLocal[i]/fcmpCountListLocal[i], fcmpCountListLocal[i]);
        }
    }
    
    fclose(profileFile);
}
