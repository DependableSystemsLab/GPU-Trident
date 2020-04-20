#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <math.h>
#include <cuda.h>
#define TX 16
#define TY 32


//#ifdef BAMBOO_PROFILING
//#include "bamboo_profiling.cu"
//#else
#include "record_data.cu"
//#endif

static int const maxlen = 200, rowsize = 521, colsize = 428, linelen = 12;
struct timeval tim;

__global__
void ProcessBlurKernel(int *d_R, int *d_G, int *d_B, int *d_Rnew, int *d_Gnew, int *d_Bnew)
{
	int row = blockIdx.y*blockDim.y+threadIdx.y;
	int col = blockIdx.x*blockDim.x+threadIdx.x;

	int temp = row*colsize+col;
	int temp1 = (row+1)*colsize+col;
	int temp2 = (row-1)*colsize+col;
	int temp3 = row*colsize+(col+1);
	int temp4 = row*colsize+(col-1);



	if(col<colsize && row<rowsize)
	{
		if (row != 0 && row != (rowsize-1) && col != 0 && col != (colsize-1)){
					d_Rnew[temp] = (d_R[temp1]+d_R[temp2]+d_R[temp3]+d_R[temp4])/4;
					d_Gnew[temp] = (d_G[temp1]+d_G[temp2]+d_G[temp3]+d_G[temp4])/4;
					d_Bnew[temp] = (d_B[temp1]+d_B[temp2]+d_B[temp3]+d_B[temp4])/4;
				}
				else if (row == 0 && col != 0 && col != (colsize-1)){
					d_Rnew[temp] = (d_R[temp1]+d_R[temp3]+d_R[temp4])/3;
					d_Gnew[temp] = (d_G[temp1]+d_G[temp3]+d_G[temp4])/3;
					d_Bnew[temp] = (d_B[temp1]+d_B[temp3]+d_B[temp4])/3;
				}
				else if (row == (rowsize-1) && col != 0 && col != (colsize-1)){
					d_Rnew[temp] = (d_R[temp2]+d_R[temp3]+d_R[temp4])/3;
					d_Gnew[temp] = (d_G[temp2]+d_G[temp3]+d_G[temp4])/3;
					d_Bnew[temp] = (d_B[temp2]+d_B[temp3]+d_B[temp4])/3;
				}
				else if (col == 0 && row != 0 && row != (rowsize-1)){
					d_Rnew[temp] = (d_R[temp1]+d_R[temp2]+d_R[temp3])/3;
					d_Gnew[temp] = (d_G[temp1]+d_G[temp2]+d_G[temp3])/3;
					d_Bnew[temp] = (d_B[temp1]+d_B[temp2]+d_B[temp3])/3;
				}
				else if (col == (colsize-1) && row != 0 && row != (rowsize-1)){
					d_Rnew[temp] = (d_R[temp1]+d_R[temp2]+d_R[temp4])/3;
					d_Gnew[temp] = (d_G[temp1]+d_G[temp2]+d_G[temp4])/3;
					d_Bnew[temp] = (d_B[temp1]+d_B[temp2]+d_B[temp4])/3;
				}
				else if (row==0 &&col==0){
					d_Rnew[temp] = (d_R[temp3]+d_R[temp1])/2;
					d_Gnew[temp] = (d_G[temp3]+d_G[temp1])/2;
					d_Bnew[temp] = (d_B[temp3]+d_B[temp1])/2;
				}
				else if (row==0 &&col==(colsize-1)){
					d_Rnew[temp] = (d_R[temp4]+d_R[temp1])/2;
					d_Gnew[temp] = (d_G[temp4]+d_G[temp1])/2;
					d_Bnew[temp] = (d_B[temp4]+d_B[temp1])/2;
				}
				else if (row==(rowsize-1) &&col==0){
					d_Rnew[temp] = (d_R[temp3]+d_R[temp2])/2;
					d_Gnew[temp] = (d_G[temp3]+d_G[temp2])/2;
					d_Bnew[temp] = (d_B[temp3]+d_B[temp2])/2;
				}
				else if (row==(rowsize-1) &&col==(colsize-1)){
					d_Rnew[temp] = (d_R[temp4]+d_R[temp2])/2;
					d_Gnew[temp] = (d_G[temp4]+d_G[temp2])/2;
					d_Bnew[temp] = (d_B[temp4]+d_B[temp2])/2;
				}	
	}
}

__global__
void doCopyKernel(int *d_R, int *d_G, int *d_B, int *d_Rnew, int *d_Gnew, int *d_Bnew)
{
	int row = blockIdx.y*blockDim.y+threadIdx.y;
	int col = blockIdx.x*blockDim.x+threadIdx.x;
	int temp = row*colsize+col;
	if(col<colsize && row<rowsize)
	{
		d_R[temp] = d_Rnew[temp];
		d_G[temp] = d_Gnew[temp];
		d_B[temp] = d_Bnew[temp];
	}
}
void ProcessBlur(int R[rowsize][colsize], int G[rowsize][colsize], int B[rowsize][colsize], int Rnew[rowsize][colsize], int Gnew[rowsize][colsize], int Bnew[rowsize][colsize], int nblurs)
{


	int *d_R, *d_G, *d_B, *d_Rnew, *d_Gnew, *d_Bnew;

	int k;
	int sizea =sizeof(int)*rowsize*colsize;
	
	gettimeofday(&tim, NULL);
	double t5=tim.tv_sec+(tim.tv_usec/1000000.0);

	cudaMalloc((void **)&d_R,sizea);
	cudaMalloc((void **)&d_G,sizea);
	cudaMalloc((void **)&d_B,sizea);
	cudaMalloc((void **)&d_Rnew,sizea);
	cudaMalloc((void **)&d_Gnew,sizea);
	cudaMalloc((void **)&d_Bnew,sizea);

	gettimeofday(&tim, NULL);
	double t6=tim.tv_sec+(tim.tv_usec/1000000.0);
	printf("Allocation of device memory: %.6lf seconds elapsed\n", t6-t5);

	gettimeofday(&tim, NULL);
	double t7=tim.tv_sec+(tim.tv_usec/1000000.0);
	
	cudaMemcpy(d_R,R,sizea,cudaMemcpyHostToDevice);
	cudaMemcpy(d_G,G,sizea,cudaMemcpyHostToDevice);
	cudaMemcpy(d_B,B,sizea,cudaMemcpyHostToDevice);
	dim3 dimGrid(ceil(rowsize/(float)TX),ceil(colsize/(float)TY),1);
	dim3 dimBlock(TX,TY,1);
	
	gettimeofday(&tim, NULL);
	double t1=tim.tv_sec+(tim.tv_usec/1000000.0);

	for(k=0;k<nblurs;k++){

		 bambooLogKernelBegin(k);
		 ProcessBlurKernel<<<dimGrid,dimBlock>>>(d_R,d_G,d_B,d_Rnew,d_Gnew,d_Bnew);
		 bambooLogRecordOff();

		 //bambooLogKernelBegin(1);
		 doCopyKernel<<<dimGrid,dimBlock>>>(d_R,d_G,d_B,d_Rnew,d_Gnew,d_Bnew);
		 //bambooLogKernelEnd(1);
	}

	bambooLogKernelEnd();
	
	cudaThreadSynchronize();

	gettimeofday(&tim, NULL);
	double t2=tim.tv_sec+(tim.tv_usec/1000000.0);
	printf("Doing the blurring: %.6lf seconds elapsed\n", t2-t1);
	    

	    cudaMemcpy(R,d_Rnew,sizea,cudaMemcpyDeviceToHost);
	    cudaMemcpy(G,d_Gnew,sizea,cudaMemcpyDeviceToHost);
	    cudaMemcpy(B,d_Bnew,sizea,cudaMemcpyDeviceToHost);

	gettimeofday(&tim, NULL);
	double t8=tim.tv_sec+(tim.tv_usec/1000000.0);
	printf("Transfer data: %.6lf seconds elapsed\n", t8-(t2-t1)-t7);

	    cudaFree(d_R);
		cudaFree(d_G);
		cudaFree(d_B);
		cudaFree(d_Rnew);
		cudaFree(d_Gnew);
		cudaFree(d_Bnew);
	
}

int main (int argc, const char * argv[]) {
	char str[maxlen], lines[5][maxlen];
	FILE *fp, *fout;
	int nlines = 0;
	unsigned int h1, h2, h3;
	char *sptr;
	int R[rowsize][colsize], G[rowsize][colsize], B[rowsize][colsize];
	int Rnew[rowsize][colsize], Gnew[rowsize][colsize], Bnew[rowsize][colsize];
	int row = 0, col = 0, nblurs, lineno=0;
	nblurs = 10;
    printf("\nGive the number of times to blur the image\n");
    //int icheck = scanf ("%d", &nblurs);
	nblurs = 1;
	
	gettimeofday(&tim, NULL);
	double t3=tim.tv_sec+(tim.tv_usec/1000000.0);
	
	fp = fopen("David.ps", "r");
 
	while(! feof(fp))
	{
		fscanf(fp, "\n%[^\n]", str);
		if (nlines < 5) {strcpy((char *)lines[nlines++],(char *)str);}
		else{
			for (sptr=&str[0];*sptr != '\0';sptr+=6){
				sscanf(sptr,"%2x",&h1);
				sscanf(sptr+2,"%2x",&h2);
				sscanf(sptr+4,"%2x",&h3);
				
				if (col==colsize){
					col = 0;
					row++;
				}
				if (row < rowsize) {
					R[row][col] = h1;
					G[row][col] = h2;
					B[row][col] = h3;
				}
				col++;
			}
		}
	}
	fclose(fp);
	
	gettimeofday(&tim, NULL);
	double t4=tim.tv_sec+(tim.tv_usec/1000000.0);
	printf("Reading input file: %.6lf seconds elapsed\n", t4-t3);


	ProcessBlur(R,G,B,Rnew,Gnew,Bnew,nblurs);//blur the picture


    gettimeofday(&tim, NULL);
	double t9=tim.tv_sec+(tim.tv_usec/1000000.0);

	fout= fopen("DavidBlur.ps", "w");
	int k=0;
	for (k=0;k<nlines;k++) fprintf(fout,"\n%s", lines[k]);
	fprintf(fout,"\n");
	for(row=0;row<rowsize;row++){
		for (col=0;col<colsize;col++){
			fprintf(fout,"%02x%02x%02x",R[row][col],G[row][col],B[row][col]);
			lineno++;
			if (lineno==linelen){
				fprintf(fout,"\n");
				lineno = 0;
			}
		}
	}
	fclose(fout);
	gettimeofday(&tim, NULL);
	double t10=tim.tv_sec+(tim.tv_usec/1000000.0);
	printf("Outputting: %.6lf seconds elapsed\n", t10-t9);

    return 0;
}
