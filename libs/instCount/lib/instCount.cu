#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ unsigned long long instCountList[LIST_SIZE];
__device__ int init_flag = 0;


extern "C" __device__ void profileCount(long index){
    
	if(init_flag == 0){
		int i = 0;
		for(i=0;i<LIST_SIZE;i++){
			instCountList[i] = 0;
		}
		//init_flag = 1;
		atomicAdd(&init_flag, 1);
	}
    
    atomicAdd(&instCountList[index], 1);
}
