#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ int init_flag = 0;
__device__ unsigned long long shiftCount[LIST_SIZE];
__device__ unsigned long long shiftVal[LIST_SIZE];


extern "C" __device__ void profileCmp(long shiftValue, long index){

    atomicAdd(&shiftCount[index],1);
    atomicAdd(&shiftCount[index],shiftValue);
/*	
	if(init_flag == 0){
		int i = 0;
		for(i=0;i<LIST_SIZE;i++){
			oneList[i] = 0;
			zeroList[i] = 0;
		}
		atomicAdd(&init_flag, 1);
	}
*/
    
}

