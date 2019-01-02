#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ int index_c = 0;
__device__ unsigned long long load_store_index[LIST_SIZE];
__device__ unsigned long long load_store_address[LIST_SIZE];
__device__ unsigned long long load_store_check[LIST_SIZE];


extern "C" __device__ void profileLoadInst(long* adress, long index){

    unsigned long long local_index = atomicAdd(&index_c,1);
    atomicAdd(&load_store_address[local_index], (long)adress);
    atomicAdd(&load_store_index[local_index], index);
    atomicAdd(&load_store_check[local_index], 0);
    
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

extern "C" __device__ void profileStoreInst(long* adress, long index){

    unsigned long long local_index = atomicAdd(&index_c,1);
    atomicAdd(&load_store_address[local_index], (long)adress);
    atomicAdd(&load_store_index[local_index], index);
    atomicAdd(&load_store_check[local_index], 1);
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

