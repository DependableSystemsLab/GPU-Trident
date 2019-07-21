#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ int init_flag = 0;
__device__ unsigned long long shiftCount[LIST_SIZE];
__device__ unsigned long long shiftVal[LIST_SIZE];
__device__ unsigned long long record_flag = 0;


extern "C" __device__ void profileShiftValues(long shiftValue, long index){

    if (record_flag != 0)
    {
        atomicAdd(&shiftCount[index],1);
        atomicAdd(&shiftCount[index],shiftValue);
    }
    
}

