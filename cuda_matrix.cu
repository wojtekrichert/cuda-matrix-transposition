#include <stdio.h>
#include <math.h>
#include <ctime>
#include <iostream>
using namespace std;
const int size =6144;
const int wym = 32;
const int rzed = 8;
const int powtorzenia = 100;

int zapelnianie(double ** matrix);

int transponowanie(double ** matrix,double **CPUmatrix){
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
  return 1;
}

int sprawdzenie(double *GPUarray, double **CPUmatrix){
  int k=0;
  for(int x=0; x<size; ++x){
    for(int y=0;y<size;++y){
      if(GPUarray[k]!=CPUmatrix[x][y]){
        printf("ups");
      }
      ++k;
    }
  }
  return 1;
}

__global__ void transpose_global(double *d_array, double *d_GPUarray){
  int x = blockIdx.x * wym + threadIdx.x;
  int y = blockIdx.y * wym + threadIdx.y;
  int width = gridDim.x * wym;
    for (int j = 0; j < wym; j+= rzed){
      d_GPUarray[x*width + (y+j)] = d_array[(y+j)*width + x];
    }
}

__global__ void transpose_shared(double *d_array, double *d_GPUsharedarray){
  __shared__ double lol[wym][wym+1];

  int x = blockIdx.x * wym + threadIdx.x;
  int y = blockIdx.y * wym + threadIdx.y;
  int width = gridDim.x * wym;

  for (int j = 0; j < wym; j += rzed)
     lol[threadIdx.y+j][threadIdx.x] = d_array[(y+j)*width + x];

  __syncthreads();

  x = blockIdx.y * wym + threadIdx.x;
  y = blockIdx.x * wym + threadIdx.y;

  for (int j = 0; j < wym; j += rzed)
     d_GPUsharedarray[(y+j)*width + x] = lol[threadIdx.x][threadIdx.y + j];
}

int main(void){
  dim3 dimGrid(size/wym, size/wym, 1);
  dim3 dimBlock(wym, rzed, 1);
  //transponowanie na CPU:-------------------------------
  clock_t begin1 = clock();
  double ** matrix= new double *[size];
  double ** CPUmatrix= new double *[size];
  for(int i = 0; i < size; ++i){
    matrix[i]= new double[size];
    CPUmatrix[i]= new double[size];
  }
  zapelnianie(matrix);
  transponowanie(matrix,CPUmatrix);
  clock_t end1 = clock();
  double elapsed_secs1 = (double(end1 - begin1) / CLOCKS_PER_SEC);
  //----------------------------------------------------



  double *array,*d_array, *GPUarray, *d_GPUarray, *d_GPUsharedarray, *GPUsharedarray;
  array = (double*)malloc(size*size*sizeof(double));
  GPUarray = (double*)malloc(size*size*sizeof(double));
  GPUsharedarray = (double*)malloc(size*size*sizeof(double));
  //splaszczenie 2d matrix na 1d array:----------------------
  int k=0;
  for(int x=0; x<size; ++x){
    for(int y=0;y<size;++y){
      array[k]=matrix[x][y];
      ++k;
    }
  }
  //---------------------------------------------------------
  cudaMalloc(&d_GPUarray, size*size*sizeof(double));
  cudaMalloc(&d_array, size*size*sizeof(double));
  cudaMalloc(&d_GPUsharedarray, size*size*sizeof(double));
  cudaMemcpy(d_array, array, size*size*sizeof(double), cudaMemcpyHostToDevice);
  cudaMemcpy(d_GPUarray, GPUarray, size*size*sizeof(double), cudaMemcpyHostToDevice);
  cudaMemcpy(d_GPUsharedarray, GPUsharedarray, size*size*sizeof(double), cudaMemcpyHostToDevice);

  //transpozycja z uzyciem pamieci globalnej:-------------------------
  clock_t begin = clock();
  transpose_global<<<dimGrid, dimBlock>>>(d_array, d_GPUarray);
  for (int i = 0; i < powtorzenia; i++){
    transpose_global<<<dimGrid, dimBlock>>>(d_array, d_GPUarray);
  }
  cudaMemcpy(GPUarray, d_GPUarray,size*size*sizeof(double), cudaMemcpyDeviceToHost);
  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  sprawdzenie(GPUarray, CPUmatrix);
  //-------------------------------------------------------------------

  //transpozycja z uzyciem pamieci shared : ---------------------
  clock_t begin2 = clock();
  transpose_shared<<<dimGrid, dimBlock>>>(d_array,d_GPUsharedarray);
  for (int a = 0; a < powtorzenia; a++){
    transpose_shared<<<dimGrid, dimBlock>>>(d_array,d_GPUsharedarray);
  }

  cudaMemcpy(GPUsharedarray, d_GPUsharedarray,size*size*sizeof(double), cudaMemcpyDeviceToHost);
  clock_t end2 = clock();
  double elapsed_secs2 = double(end2 - begin2) / CLOCKS_PER_SEC;

  printf("czas CPU: %f \n", elapsed_secs1);
  printf("czas GPU global: %f ", elapsed_secs);
  printf("\nczas GPU shared: %f \n", elapsed_secs2);
  sprawdzenie(GPUsharedarray, CPUmatrix);

  //-------------------------------------------------------------
  cudaFree(d_GPUarray);
  cudaFree(d_array);
  cudaFree(d_GPUsharedarray);



}

























int zapelnianie(double ** matrix){
  for(int i = 0; i < size; ++i)
    for(int j = 0; j < size; ++j)
      matrix[i][j] = i*size+j;
  /*
  for(int i = 0; i < size; ++i)
    for(int j = 0; j < size; ++j)
      cout << matrix[i][j] << " ";
  */
  sleep(1000);
  return 1;
}
