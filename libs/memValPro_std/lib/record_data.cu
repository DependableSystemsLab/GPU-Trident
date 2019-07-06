#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE_GLOBAL 5000000
#define LIST_SIZE 10000
extern "C" __device__ unsigned  long long load_store_index[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_value[LIST_SIZE];
extern "C" __device__ double load_store_double[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_double_index[LIST_SIZE];
extern "C" __device__ unsigned long long record_flag;
extern "C" __device__ unsigned long long call_count;

int memPro_kernel = 0;

void bambooLogRecordOff(){

    long long local_record = 0;

    cudaMemcpyToSymbol(record_flag, &local_record, sizeof(long long), 0, cudaMemcpyHostToDevice);
}


void bambooLogKernelBegin(long long i) {

    cudaMemcpyToSymbol(call_count, &i, sizeof(long long), 0, cudaMemcpyHostToDevice);

    i = 1;

    cudaMemcpyToSymbol(record_flag, &i, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelEnd()
{

    unsigned long long loadStoreIndex[LIST_SIZE] = {0};
    unsigned long long loadStoreValue[LIST_SIZE] = {0};

    unsigned long long loadStoreIndex_double[LIST_SIZE] = {0};
    double loadStoreValue_double[LIST_SIZE] = {0};

    FILE *profileFile = fopen("profile_mem_val_result.txt", "a");

    
    for (int j=0; j < LIST_SIZE_GLOBAL; j+=LIST_SIZE)
    {
        cudaMemcpyFromSymbol(&loadStoreIndex, load_store_index, LIST_SIZE * sizeof(unsigned long long), j*sizeof(unsigned long long), cudaMemcpyDeviceToHost);
        cudaMemcpyFromSymbol(&loadStoreValue, load_store_value, LIST_SIZE * sizeof(unsigned long long), j*sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    
        for(long long i=0; i < LIST_SIZE && loadStoreIndex[i] != 0; i++)
        {

           fprintf(profileFile, "%lld %lld\n", loadStoreIndex[i], loadStoreValue[i]);   
        }
    }
    
    for (int j=0; j < LIST_SIZE_GLOBAL; j+=LIST_SIZE)
    {
        cudaMemcpyFromSymbol(&loadStoreIndex_double, load_store_double_index, LIST_SIZE * sizeof(unsigned long long), j*sizeof(unsigned long long), cudaMemcpyDeviceToHost);
        cudaMemcpyFromSymbol(&loadStoreValue_double, load_store_double, LIST_SIZE * sizeof(double), j*sizeof(double), cudaMemcpyDeviceToHost);
    
        for(long long i=0; i < LIST_SIZE && loadStoreIndex_double[i] != 0; i++)
        {

           fprintf(profileFile, "%lld %.40f\n", loadStoreIndex_double[i], loadStoreValue_double[i]);   
        }
    }
    
    fclose(profileFile);
}
