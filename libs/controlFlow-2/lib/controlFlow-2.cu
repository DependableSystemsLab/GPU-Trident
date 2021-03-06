#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include "local_param.h"

__device__ float control_flow_rec[Y_MAX][X_MAX][CF_2_NUM];
__device__ int count[Y_MAX][X_MAX];
__device__ unsigned long long record_flag = 0;

extern "C" __device__ void profileCmp(int cmpResult, long index)
{
    if (record_flag == 0)
        return;

    float a = (float)cmpResult/10;
    
    if (index < START_LOOP || index > END_LOOP)
    {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;  
        int idy = blockIdx.y * blockDim.y + threadIdx.y;

        unsigned long long local_index = atomicAdd(&count[idy][idx],1);

        control_flow_rec[idy][idx][local_index] = (float)index + a;
    }
}

