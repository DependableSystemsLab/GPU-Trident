#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 500000
__device__ int index_c = 0;
__device__ unsigned long long load_store_index[LIST_SIZE];
__device__ unsigned long long load_store_address[LIST_SIZE];
__device__ unsigned long long load_store_check[LIST_SIZE];
__device__ unsigned long long record_flag = 0;


extern "C" __device__ void profileLoadInst(long* adress, long index){

    //int idx = blockIdx.x * blockDim.x + threadIdx.x;  
    //int idy = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (record_flag != 0)
    {
        unsigned long long local_index = atomicAdd(&index_c,1);
        atomicAdd(&load_store_address[local_index], (long)adress);
        atomicAdd(&load_store_index[local_index], index);
        atomicAdd(&load_store_check[local_index], 0);
    }    
}

extern "C" __device__ void profileStoreInst(long* adress, long index){

    //int idx = blockIdx.x * blockDim.x + threadIdx.x;  
    //int idy = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (record_flag != 0)
    {
        unsigned long long local_index = atomicAdd(&index_c,1);
        atomicAdd(&load_store_address[local_index], (long)adress);
        atomicAdd(&load_store_index[local_index], index);
        atomicAdd(&load_store_check[local_index], 1);
    }
}

