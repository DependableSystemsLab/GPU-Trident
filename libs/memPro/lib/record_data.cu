#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 2000
#define LIST_SIZE_GLOBAL 500000

extern "C" __device__ unsigned long long load_store_index[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_address[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_check[LIST_SIZE];
extern "C" __device__ unsigned long long record_flag;
extern "C" __device__ int index_c;

void bambooLogRecordOff(){

    long long local_record = 0;

    cudaMemcpyToSymbol(record_flag, &local_record, sizeof(long long), 0, cudaMemcpyHostToDevice);
}

void bambooLogKernelBegin(long long i) {

    i = 1;

    cudaMemcpyToSymbol(record_flag, &i, sizeof(long long), 0, cudaMemcpyHostToDevice);
    
    cudaMemcpyFromSymbol(&i, index_c, sizeof(int), 0, cudaMemcpyDeviceToHost);
    
    printf("How much:%lld\n\n", i);
}

void bambooLogKernelEnd()
{
    
    long long i = 0;
    
    cudaMemcpyFromSymbol(&i, index_c, sizeof(int), 0, cudaMemcpyDeviceToHost);
    
    printf("How much End:%lld\n\n", i);
    
	cudaDeviceSynchronize();

	unsigned long long loadStoreIndex[LIST_SIZE] = {0};
	unsigned long long loadStoreAddress[LIST_SIZE] = {0};
	unsigned long long loadStoreCheck[LIST_SIZE] = {0};
	
	FILE *profileFile = fopen("profile_mem_result.txt", "w");


    for (long long j = 0; j <  LIST_SIZE_GLOBAL; j += LIST_SIZE)
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
/*
	memset(loadStoreIndex, 0, sizeof(loadStoreIndex));
	memset(loadStoreAddress, 0, sizeof(loadStoreAddress));
	memset(loadStoreCheck, 0, sizeof(loadStoreCheck));
	
	cudaMemcpyToSymbol(load_store_index, &loadStoreIndex, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(load_store_address, &loadStoreAddress, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(load_store_check, &loadStoreCheck, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
*/	
}
