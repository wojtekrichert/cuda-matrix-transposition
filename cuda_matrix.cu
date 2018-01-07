#include <stdio.h>
#include <math.h>
#include <ctime>
#include <iostream>
using namespace std;
const int size =1024;
const int TILE_DIM = 32;
const int BLOCK_ROWS = 8;
const int NUM_REPS = 100;

int zapelnianie(double ** matrix){
  for(int i = 0; i < size; ++i)
    for(int j = 0; j < size; ++j)
      matrix[i][j] = i*size+j;
  /*
  for(int i = 0; i < size; ++i)
    for(int j = 0; j < size; ++j)
      cout << matrix[i][j] << " ";
  */
  return 1;
}

int transponowanie(double ** matrix,double **CPUmatrix){
  clock_t begin = clock();
  for(int i=0; i<size;i++){
    for(int j=0; j<size;j++){
      CPUmatrix[j][i]=matrix[i][j];
    }
  }
  for( int x=0 ; x<size; x++){
    for(int y=0; y<size; y++){
      if(matrix[x][y]==CPUmatrix[x][y] && x!=y)
      printf("ups");
    }
  }
  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  printf("czas CPU: %f \n", elapsed_secs);
  return 1;
}

__global__ void transpose_global(double *d_array, double *d_GPUarray){
  int x = blockIdx.x * TILE_DIM + threadIdx.x;
  int y = blockIdx.y * TILE_DIM + threadIdx.y;
  int width = gridDim.x * TILE_DIM;
    for (int j = 0; j < TILE_DIM; j+= BLOCK_ROWS){
      d_GPUarray[x*width + (y+j)] = d_array[(y+j)*width + x];
    }
}

int main(void){
  dim3 dimGrid(size/TILE_DIM, size/TILE_DIM, 1);
  dim3 dimBlock(TILE_DIM, BLOCK_ROWS, 1);

  double ** matrix= new double *[size];
  double ** CPUmatrix= new double *[size];
  for(int i = 0; i < size; ++i){
    matrix[i]= new double[size];
    CPUmatrix[i]= new double[size];
  }
  zapelnianie(matrix);

  transponowanie(matrix,CPUmatrix);
  
  double *array,*d_array, *GPUarray, *d_GPUarray;
  array = (double*)malloc(size*size*sizeof(double));
  GPUarray = (double*)malloc(size*size*sizeof(double));
  int k=0;
  for(int x=0; x<size; ++x){
    for(int y=0;y<size;++y){
      array[k]=matrix[x][y];
      ++k;
    }
  }
  cudaMalloc(&d_GPUarray, size*size*sizeof(double));
  cudaMalloc(&d_array, size*size*sizeof(double));
  cudaMemcpy(d_array, array, size*size*sizeof(double), cudaMemcpyHostToDevice);
  cudaMemcpy(d_GPUarray, GPUarray, size*size*sizeof(double), cudaMemcpyHostToDevice);
  clock_t begin = clock();
  transpose_global<<<dimGrid, dimBlock>>>(d_array, d_GPUarray);
  for (int i = 0; i < NUM_REPS; i++){
    transpose_global<<<dimGrid, dimBlock>>>(d_array, d_GPUarray);
      cudaDeviceSynchronize();
  }
  cudaMemcpy(GPUarray, d_GPUarray,size*size*sizeof(double), cudaMemcpyDeviceToHost);
  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  printf("\nczas GPU: %f \n", elapsed_secs);

cudaFree(d_GPUarray);
cudaFree(d_array);



}
