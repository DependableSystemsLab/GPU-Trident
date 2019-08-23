#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <cuda.h>
#include <device_launch_parameters.h>
#include "local_param.h"

extern "C" __device__ float control_flow_rec[Y_MAX][X_MAX][CF_2_NUM];
extern "C" __device__ int count[Y_MAX][X_MAX];

int lc;

void bambooLogKernelBegin(long long int invoc_count) {

    float controlflow[CF_2_NUM];
    int local_count[1] = {0};

    memset(controlflow, 0, sizeof(controlflow));
    
    for (long long i =0; i < Y_MAX; i++)
    {
        for (long long j =0; j < X_MAX; j++)
        {
            cudaMemcpyToSymbol(control_flow_rec, controlflow, CF_2_NUM * sizeof(float), j*CF_2_NUM*sizeof(float) + sizeof(float)*i*X_MAX*CF_2_NUM, cudaMemcpyHostToDevice);
            cudaMemcpyToSymbol(count, local_count, sizeof(int), j* sizeof(int) + sizeof(int)*i*X_MAX, cudaMemcpyHostToDevice);
        }
    }

    lc = invoc_count;
}

void bambooLogRecordOff()
{
    cudaDeviceSynchronize();

    float controlflow[CF_2_NUM];

    memset(controlflow, 0, sizeof(controlflow));

    int temp;
    char cond_str;
    
    FILE *profileFile1 = fopen("control_flow_group-2.txt", "a");

    for (long long k = 0; k < Y_MAX; k++)
    {
        for (long long j =0; j < X_MAX; j++)
        {
            cudaMemcpyFromSymbol(controlflow, control_flow_rec, CF_2_NUM * sizeof(float), j*CF_2_NUM*sizeof(float) + sizeof(float)*k*X_MAX*CF_2_NUM, cudaMemcpyDeviceToHost);

            fprintf(profileFile1, "%d %lld %lld:", lc, j, k);

            for (long long i = 0; i < CF_2_NUM && controlflow[i] != 0; i++)
            {
                temp = (int)floor(controlflow[i]);

                cond_str = (controlflow[i] > (float)temp) ? 'T' : 'F';

                fprintf(profileFile1, "%d%c", temp, cond_str);
            }

            fprintf(profileFile1, "\n");
        }
    }

    fclose(profileFile1);
}

void bambooLogKernelEnd()
{

}
