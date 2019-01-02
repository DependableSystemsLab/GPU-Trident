#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ int init_flag = 0;
__device__ unsigned long long zeroList[LIST_SIZE];
__device__ unsigned long long oneList[LIST_SIZE];


extern "C" __device__ void profileCmp(int cmpResult, long index){
	
	if(init_flag == 0){
		int i = 0;
		for(i=0;i<LIST_SIZE;i++){
			oneList[i] = 0;
			zeroList[i] = 0;
		}
		atomicAdd(&init_flag, 1);
	}

    if (cmpResult == 0)
    {
        atomicAdd(&zeroList[index],1);
    }
    else
    {
        atomicAdd(&oneList[index],1);
    }
}

