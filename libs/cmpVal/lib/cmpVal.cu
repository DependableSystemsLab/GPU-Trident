#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define LIST_SIZE 10000
__device__ int init_flag = 0;
__device__ unsigned long long icmpValue1List[LIST_SIZE];
__device__ unsigned long long icmpValue2List[LIST_SIZE];
__device__ double fcmpValue1List[LIST_SIZE];
__device__ double fcmpValue2List[LIST_SIZE];
__device__ unsigned long long icmpCountList[LIST_SIZE];
__device__ unsigned long long fcmpCountList[LIST_SIZE];
__device__ unsigned long long record_flag;

/* Overloading the atomic add function for CUDA, as it is not available for computer capability < 6.0.0 */
#if __CUDA_ARCH__ < 600
__device__ double atomicAdd(double* address, double val)
{
    unsigned long long int* address_as_ull =
                              (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(val +
                               __longlong_as_double(assumed)));

    // Note: uses integer comparison to avoid hang in case of NaN (since NaN != NaN)
    } while (assumed != old);

    return __longlong_as_double(old);
}
#endif

extern "C" __device__ void profileICmpValue(long cmpValue1,long cmpValue2, long index)
{
    if (record_flag == 0)
        return;
        
    atomicAdd(&icmpCountList[index],1);
    atomicAdd(&icmpValue1List[index], cmpValue1);
    atomicAdd(&icmpValue2List[index], cmpValue2);
}

extern "C" __device__ void profileFCmpValue(double cmpValue1,double cmpValue2, long index)
{
    if (record_flag == 0)
        return;
        
    atomicAdd(&fcmpCountList[index],1);
    atomicAdd(&fcmpValue1List[index], cmpValue1);
    atomicAdd(&fcmpValue2List[index], cmpValue2);
}

