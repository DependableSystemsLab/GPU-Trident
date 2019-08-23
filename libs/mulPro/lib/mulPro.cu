#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 100000
__device__ int init_flag = 0;
__device__ unsigned long long mulValue1List[LIST_SIZE];
__device__ unsigned long long mulValue2List[LIST_SIZE];
__device__ unsigned long long mulCountList[LIST_SIZE];
__device__ unsigned long long record_flag;

extern "C" __device__ void profileMulValue(long mulValue1,long mulValue2, long index)
{
    if (record_flag == 0)
        return;
        
    atomicAdd(&mulCountList[index],1);
    if (mulValue1 == 0)
    {
    	atomicAdd(&mulValue1List[index], 1);
    }

    if(mulValue2 == 0)
    {
    	atomicAdd(&mulValue2List[index], 1);
    }
}

extern "C" __device__ void profileFmulValue(double mulValue1,double mulValue2, long index)
{	
    if (record_flag == 0)
        return;
       
    atomicAdd(&mulCountList[index],1);
    
    if (mulValue1 == 0)
    {
    	atomicAdd(&mulValue1List[index], 1);
    }

    if (mulValue2 == 0)
    {
    	atomicAdd(&mulValue1List[index], 1);
    }
}

