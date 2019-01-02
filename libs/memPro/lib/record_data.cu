#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#define LIST_SIZE 100000
extern "C" __device__ unsigned long long load_store_index[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_address[LIST_SIZE];
extern "C" __device__ unsigned long long load_store_check[LIST_SIZE];

void bambooLogKernelBegin() {

}

void bambooLogKernelEnd()
{

#ifdef KERNELTRACE
	cudaDeviceSynchronize();
#endif

	unsigned long long loadStoreIndex[LIST_SIZE] = {0};
	unsigned long long loadStoreAddress[LIST_SIZE] = {0};
	unsigned long long loadStoreCheck[LIST_SIZE] = {0};
	
	cudaMemcpyFromSymbol(&loadStoreIndex, load_store_index, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
	cudaMemcpyFromSymbol(&loadStoreAddress, load_store_address, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
	cudaMemcpyFromSymbol(&loadStoreCheck, load_store_check, LIST_SIZE * sizeof(long long), 0, cudaMemcpyDeviceToHost);
    
	FILE *profileFile = fopen("profile_mem_result.txt", "w");
	
	for(long long i=0; i < LIST_SIZE; i++){
        
        if(loadStoreIndex[i] != 0){
        
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
				
	fclose(profileFile);
	memset(loadStoreIndex, 0, sizeof(loadStoreIndex));
	memset(loadStoreAddress, 0, sizeof(loadStoreAddress));
	memset(loadStoreCheck, 0, sizeof(loadStoreCheck));
	
	cudaMemcpyToSymbol(load_store_index, &loadStoreIndex, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(load_store_address, &loadStoreAddress, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(load_store_check, &loadStoreCheck, LIST_SIZE * sizeof(long long), 0, cudaMemcpyHostToDevice);
}
