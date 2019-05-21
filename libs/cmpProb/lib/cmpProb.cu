#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ unsigned long long zeroList[LIST_SIZE];
__device__ unsigned long long oneList[LIST_SIZE];
__device__ unsigned long long record_flag = 0;


extern "C" __device__ void profileCmp(int cmpResult, long index){
	
	if (record_flag == 0)
	    return;

    if (cmpResult == 0)
    {
        atomicAdd(&zeroList[index],1);
    }
    else
    {
        atomicAdd(&oneList[index],1);
    }
}

