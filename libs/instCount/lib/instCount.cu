#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ unsigned long long instCountList[LIST_SIZE];
__device__ unsigned long long record_flag = 0;


extern "C" __device__ void profileCount(long index){
    
    if (record_flag == 0)
        return;
    
    atomicAdd(&instCountList[index], 1);
}
