#include <stdio.h>
#include <stdlib.h>
//#include "def.cuh"
#include <string.h>


#include <cuda_runtime.h>
#include <cuda.h>
#include <device_launch_parameters.h>

#ifdef BAMBOO_PROFILING
#include "record_data.cu"
#endif

__global__ void cudaSolve(double * data, double * odata);
inline void findErr(const char * filename, const int line_number);


__device__ int N = 100;
__device__ int THREADS_PER_BLOCK_X = 10;
__device__ int THREADS_PER_BLOCK_Y = 10;

int dynamic_count = 0;

int main(int argc, char **argv){

    int show_solution;
    double tol;

    if(argc == 1){
        show_solution = 0;
        tol = 1e-4;
        printf("Usage: ./q2 tol show_solution.\n");
    }  
    else{
        tol = atof(argv[1]);
        show_solution = atoi(argv[2]);
    }

    double * h_a = 0;
    double * h_a_p = 0;
    double * d_a = 0;
    double * d_a_p = 0;

    int num_elements = 100*100;
    int num_bytes = num_elements * sizeof(double);

    h_a = (double*) calloc(num_elements, sizeof(double));
    h_a_p = (double*) calloc(num_elements, sizeof(double));
    cudaMalloc((void **) &d_a, num_bytes);
    cudaMemset(d_a, 0, num_bytes);
    cudaMalloc((void **) &d_a_p, num_bytes);
    cudaMemset(d_a_p, 0, num_bytes);

    // JUSTIN: for ck
    double* h_a_ck = (double*) calloc(num_elements, sizeof(double)); //RM
    double* h_a_p_ck = (double*) calloc(num_elements, sizeof(double)); //TM
    /////////////////////


    double coef[7];
    coef[0] = 0.000001997687531;
    coef[1] = -0.000222144671839;
    coef[2] = 0.009855558615866;
    coef[3] = -0.225735238852272;
    coef[4] = 3.855137564722874;
    coef[5] = -8.706331489366162;
    coef[6] = 33.201397146850610;
    double maxite = 0;
    for(int k = 0;k<7;++k){
        maxite += coef[k];
        if(k!=6)
            maxite *= 100;
    }
    int maxiter = (int) maxite;

    dim3 dimBlock(12, 12);
    dim3 dimGrid(100/dimBlock.x, 100/dimBlock.y);
    int iter;
    double * tmp = 0 ;
    double etime = 0;  
    double resI2 = 0;

    int N = 100;
    //  GpuTimer timer;
    //  timer.Start();
    for(iter=0; iter<maxiter; iter++){
        
        bambooLogKernelBegin(dynamic_count);
        cudaSolve<<<dimGrid, dimBlock>>>(d_a_p, d_a);
        dynamic_count++;
        bambooLogRecordOff();

        if(iter%10==0){
            // timer.Stop();
            //     etime += timer.Elapsed();
            cudaMemcpy(h_a, d_a, num_bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(h_a_p, d_a_p, num_bytes, cudaMemcpyDeviceToHost);  
            resI2 = 0;
            for(int i = 0; i<N; ++i){
                for(int j = 0; j<N; ++j){
                    resI2 += (h_a_p[i*N+j]-h_a[i*N+j])*(h_a_p[i*N+j]-h_a[i*N+j]);
                }
            }
            if(resI2 < tol*tol){
                break;
            }
            // timer.Start();
        }
        tmp = d_a_p;
        d_a_p = d_a;
        d_a = tmp;
    }

    bambooLogKernelEnd();

    //timer.Stop();
    //  etime += timer.Elapsed();

    findErr(__FILE__, __LINE__);
    cudaMemcpy(h_a, d_a, num_bytes, cudaMemcpyDeviceToHost);
    findErr(__FILE__, __LINE__);
    
    printf("Time elapsed = %g ms \n", etime);
    printf("Top right current = %lg\n", h_a[N*N-1]);
    printf("Iteration = %d\n", iter);
    printf("Bandwidth = %g GB/s\n", (N*N*sizeof(double)*2*iter/1e9)/(etime/1e3));

    if(show_solution == 1){
        FILE *fpo_result = fopen("result.txt","a");

        for(int i = 0; i<N;++i){
            for(int j = 0; j<N;++j){
                //printf("%f ", h_a[i*N+j]);
                fprintf(fpo_result, "%f ", h_a[i*N+j]);
            }
            //printf("\n");
            fprintf(fpo_result, "\n");
        }
        fclose(fpo_result);
    }

    free(h_a);
    free(h_a_p);
    cudaFree(d_a);
    cudaFree(d_a_p);

}

inline void findErr(const char * filename, const int line_number){

    //#ifdef DEBUG
    cudaThreadSynchronize();
    cudaError_t error = cudaGetLastError();
    if(error != cudaSuccess){
        printf("CUDA error at %s:%i: %s\n", filename, line_number, cudaGetErrorString(error));
        exit(-1);
    }
    //#endif

}

__global__ void cudaSolve(double * data, double * odata)
{

  int i = blockDim.y * blockIdx.y + threadIdx.y;
  int j = blockDim.x * blockIdx.x + threadIdx.x;

  int li = threadIdx.y;
  int lj = threadIdx.x;

  int e_li = li + 1;
  int e_lj = lj + 1;

  __shared__ float sdata[12][12];

  unsigned int index = i*N + j;

  if(li < 1){
    if(blockIdx.y > 0){
      sdata[li][e_lj] = data[index - N];
    }
    else{
      sdata[li][e_lj] = 0;
    }

    if(blockIdx.y < (gridDim.y - 1)){
      sdata[e_li + THREADS_PER_BLOCK_Y][e_lj] = data[index + THREADS_PER_BLOCK_Y * N];
    }
    else{
      sdata[e_li + THREADS_PER_BLOCK_Y][e_lj] = 0;
    }
  }

  if(lj < 1){
    if(blockIdx.x > 0){
      sdata[e_li][lj] = data[index - 1];
    }
    else{
      sdata[e_li][lj] = 0;
    }

    if(blockIdx.x < (gridDim.x - 1)){
      sdata[e_li][e_lj + THREADS_PER_BLOCK_X] = data[index + THREADS_PER_BLOCK_X];
    }
    else{
      sdata[e_li][e_lj + THREADS_PER_BLOCK_X] = 0;
    }
  }

  sdata[e_li][e_lj] = data[index];

  double V, invD;

  if(i==0 && j==0){
    V = 1;
    invD = 1./3;
  }
  else{
    V = 0;
    invD = 1./4;
  }

  __syncthreads();

  odata[index] = invD*(V - sdata[e_li-1][e_lj] - sdata[e_li+1][e_lj]
               - sdata[e_li][e_lj-1] - sdata[e_li][e_lj+1]);

}