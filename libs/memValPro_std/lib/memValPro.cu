#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define INDEX
#define LIST_SIZE 5000000
__device__ int index_int = 0;
__device__ int index_float = 0;

__device__ unsigned long long load_store_index[LIST_SIZE] = {0};
__device__ unsigned long long load_store_value[LIST_SIZE] = {0};
__device__ double load_store_double[LIST_SIZE] = {0.0};
__device__ unsigned long long load_store_double_index[LIST_SIZE] = {0};
__device__ unsigned long long record_flag;
__device__ unsigned long long call_count;

extern "C" __device__ void profileStoreInst(long value, long index){

    if (record_flag == 0)
        return;

    if (INDEX)
    {
        long local_index = atomicAdd(&index_int,1);
        load_store_value[local_index] = (unsigned long long)value;
        load_store_index[local_index] = (unsigned long long)index;
    }
}

extern "C" __device__ void profileStoreInstfloat(double value, long index){

    if (record_flag == 0)
        return;

    if (INDEX)
    {
        long local_index = atomicAdd(&index_float,1);
        load_store_double[local_index] = value;
        load_store_double_index[local_index] = index;
    } 
}

