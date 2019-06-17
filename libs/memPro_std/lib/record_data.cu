#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE_GLOBAL 3000000
#define LIST_SIZE 10000
extern "C" __device__ unsigned  long long load_store_index[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_address[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_check[LIST_SIZE];
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
    unsigned long long loadStoreAddress[LIST_SIZE] = {0};
    unsigned long long loadStoreCheck[LIST_SIZE] = {0};

    FILE *profileFile = fopen("profile_mem_result.txt", "a");

    for (int j=0; j < LIST_SIZE_GLOBAL; j+=LIST_SIZE)
    {
        cudaMemcpyFromSymbol(loadStoreIndex, load_store_index, LIST_SIZE * sizeof(long long), j*sizeof(long long), cudaMemcpyDeviceToHost);
        cudaMemcpyFromSymbol(loadStoreAddress, load_store_address, LIST_SIZE * sizeof(long long), j*sizeof(long long), cudaMemcpyDeviceToHost);
        cudaMemcpyFromSymbol(loadStoreCheck, load_store_check, LIST_SIZE * sizeof(long long), j*sizeof(long long), cudaMemcpyDeviceToHost);
    
        for(long long i=0; i < LIST_SIZE; i++)
        {
            if(loadStoreIndex[i] != 0)
            {
        
                if (loadStoreCheck[i] == 0)
                {
                    fprintf(profileFile, "L %lld %p\n", loadStoreIndex[i], (void*)loadStoreAddress[i]);   
                }
                else 
                {   
                    fprintf(profileFile, "S %lld %p\n", loadStoreIndex[i], (void*)loadStoreAddress[i]);   
                }
            }
        }
    }

    fclose(profileFile);
}
