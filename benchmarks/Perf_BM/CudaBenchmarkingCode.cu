#include <cstdlib>

#include<iostream>

#include<cuda.h>

#include <sys/time.h>
 //#include <cuda_fp16.h>
#include <stdio.h>

#include <stdlib.h>

#include <string.h>

#include <unistd.h>
 //#include <cuda_fp16.h>

//#define cudaCores 3584

#include "record_data.cu"

using namespace std;

FILE * fp;

int smCount, totalThreads;

//__float2half
/*void getGPUConfig(){

  cudaDeviceProp cudaProg;
  cudaGetDeviceProperties(&cudaProg,0);
  int SMCount=cudaProg.multiProcessorCount;
  int threadPerBlock=cudaProg.maxThreadsPerBlock;
  int maxThreads=SMCount*threadPerBlock;
  int numberOfBlolcks=__gcd(maxThreads,threadPerBlock);
  int numberOfThreads=maxThreads/numberOfBlolcks;
  cout << "number of blocks:"<< numberOfBlolcks<< endl;
  cout << "number of threads:"<< numberOfThreads<< endl;

}*/

__global__ void multiplyInt(int * a, int * b, int n) {

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i < n) {

        b[i] = b[i] + a[i];

    }
}

__global__ void multiplyFloat(float * a, float * b, int n) {

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i < n) {
        b[i] = b[i] + a[i];
    }
}

/*
__global__ void multiplyHalfFloat(half *a,half *b,int n)
{
  
    int i=blockIdx.x*blockDim.x+threadIdx.x;

	if(i<n){

     b[i]=__float2half(__half2float(a[i])+__half2float(a[i]));

    }
}
*/

int getSPcores(cudaDeviceProp devProp) {
    int cores = 0;
    int mp = devProp.multiProcessorCount;
    switch (devProp.major) {
    case 2: // Fermi
        if (devProp.minor == 1) cores = mp * 48;
        else cores = mp * 32;
        break;
    case 3: // Kepler
        cores = mp * 192;
        break;
    case 5: // Maxwell
        cores = mp * 128;
        break;
    case 6: // Pascal
        if ((devProp.minor == 1) || (devProp.minor == 2)) cores = mp * 128;
        else if (devProp.minor == 0) cores = mp * 64;
        else printf("Unknown device type\n");
        break;
    case 7: // Volta and Turing
        if ((devProp.minor == 0) || (devProp.minor == 5)) cores = mp * 64;
        else printf("Unknown device type\n");
        break;
    default:
        printf("Unknown device type\n");
        break;
    }
    return cores;
}

int main() {

    //fp= fopen( "GPULogs.txt", "ab" );
    cudaDeviceProp prop;
    cudaGetDeviceProperties( & prop, 0);

    int cudaCores = getSPcores(prop);
    cout << "Cuda Cores:" << cudaCores << endl;
    cout << "Device Name:" << prop.name << endl;
    //fprintf(fp,"\nDeviceName:%s",prop.name);
    cout << "Max Threads Per Block:" << prop.maxThreadsPerBlock << endl;
    //fprintf(fp,"\nMax Threads Per Block:%d",prop.maxThreadsPerBlock);
    smCount = prop.multiProcessorCount;
    cout << "SM Count is:" << smCount << endl;
    //fprintf(fp,"\nSM Count:%d",smCount);
    cout << "Warp Size:" << prop.warpSize << endl;
    //fprintf(fp,"\nWarp Size:%d",prop.warpSize);
    cout << "Clock Rate:" << prop.clockRate << endl;
    //fprintf(fp,"\nClock Rate:%d",prop.clockRate);
    totalThreads = smCount * cudaCores;
    cout << "Total Number of Threads:" << totalThreads << endl;

    int SIZE = totalThreads;

    int * a, * b;
    int * d_a, * d_b;
    float * a_f, * b_f;
    float * d_a_f, * d_b_f;
    //float *a_half,*b_half;
    //half *d_a_half,*d_b_half;

    struct timeval start_int, end_int;
    struct timeval start_float, end_float;
    //struct timeval start_half_float, end_half_float;

    a = new int[SIZE];
    b = new int[SIZE];
    a_f = new float[SIZE];
    b_f = new float[SIZE];
    //a_half=new float[SIZE];
    //b_half=new float[SIZE];

    cudaMalloc( & d_a, SIZE * sizeof(int));
    cudaMalloc( & d_b, SIZE * sizeof(int));
    cudaMalloc( & d_a_f, SIZE * sizeof(float));
    cudaMalloc( & d_b_f, SIZE * sizeof(float));
    //cudaMalloc(&d_a_half, SIZE*sizeof(half));
    //cudaMalloc(&d_b_half, SIZE*sizeof(half));

    int i;

    for (i = 0; i < SIZE; i++) {
        a[i] = i;
        b[i] = 1;
    }

    for (i = 0; i < SIZE; i++) {
        a_f[i] = i + 0.5;
        b_f[i] = i + 1.5;
    }

    /*
        for (i= 0;i< SIZE;i++) {
            a_half[i] = i+1.05;
            b_half[i] = i+2.05;
        }
    */
    cudaMemcpy(d_a, a, SIZE * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, SIZE * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_a_f, a_f, SIZE * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b_f, b_f, SIZE * sizeof(float), cudaMemcpyHostToDevice);
    //cudaMemcpy(d_a_half,a_half,SIZE*sizeof(half), cudaMemcpyHostToDevice);
    //cudaMemcpy(d_b_half,b_half,SIZE*sizeof(half), cudaMemcpyHostToDevice);

    gettimeofday( & start_int, NULL);

    for (i = 0; i < 1000; i++) {

        bambooLogKernelBegin(i);
        multiplyInt << < smCount, cudaCores >>> (d_a, d_b, SIZE);
        bambooLogRecordOff();
    }

    bambooLogKernelEnd();

    gettimeofday( & end_int, NULL);

    cudaMemcpy(b, d_b, SIZE * sizeof(int), cudaMemcpyDeviceToHost);

    gettimeofday( & start_float, NULL);

    for (i = 0; i < 1000; i++) {

        multiplyFloat << < smCount, cudaCores >>> (d_a_f, d_b_f, SIZE);
    }

    gettimeofday( & end_float, NULL);

    cudaMemcpy(b_f, d_b_f, SIZE * sizeof(float), cudaMemcpyDeviceToHost);

    //gettimeofday(&start_half_float, NULL);

    //for(i=0;i<1000;i++){

    //  multiplyHalfFloat<<<smCount,cudaCores>>>(d_a_half,d_b_half,SIZE); 

    //}

    //gettimeofday(&end_half_float, NULL); 

    //cudaMemcpy(b_half, d_b_half, SIZE*sizeof(float),cudaMemcpyDeviceToHost);

    float IOPS = ((SIZE * 1000 * cudaCores) / ((1000.0 * (end_int.tv_sec - start_int.tv_sec) + (end_int.tv_usec - start_int.tv_usec) / 1000.0) / 1000) / 1e9);

    cout << "IOPS:" << IOPS << endl;

    float FLOPS = ((SIZE * 1000 * cudaCores) / ((1000.0 * (end_float.tv_sec - start_float.tv_sec) + (end_float.tv_usec - start_float.tv_usec) / 1000.0) / 1000) / 1e9);

    cout << "GFLOPS:" << FLOPS << endl;

    //float GHOPS = ((SIZE*1000*cudaCores)/ ((1000.0 * (end_half_float.tv_sec - start_half_float.tv_sec) + (end_half_float.tv_usec - start_half_float.tv_usec) / 1000.0)/1000)/1e9);

    //cout << "GHOPS:"<< GHOPS << endl;

    //fprintf(fp,"\nGFLOPS for %s:%f",prop.name,FLOPS);
    //fprintf(fp,"\nIOPS for %s:%f",prop.name,IOPS);
    //fprintf(fp,"\nGHOPS for %s:%f",prop.name,GHOPS);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_a_f);
    cudaFree(d_b_f);
    //cudaFree(d_b_half);
    //cudaFree(d_a_half);

    return 0;
}