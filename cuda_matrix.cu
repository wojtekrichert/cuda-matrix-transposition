#include <stdio.h>
#include <math.h>
#include <ctime>

using namespace std;

int transponowanie(double tablica[1000][1000],double tab[1000][1000]){
  printf("przed: 1:%f ", tablica[0][1]);
  printf("2:%f \n", tablica[1][0]);
  for(int i=0; i<1000;i++){
    for(int j=0; j<1000;j++){
      tab[j][i]=tablica[i][j];
    }
  }
  printf("po: 1:%f ", tab[0][1]);
  printf("2:%f \n", tab[1][0]);
  return 1;
}

__global__ void transpose(double *matrix){
}


int main(void){
  clock_t begin = clock();
  static double tablica[1000][1000];
  static double tab[1000][1000];
  for(int i=0; i<1000;i++){
    for(int j=0; j<1000;j++){
      tablica[i][j]=i*1000+j+1;
    }
  }
  transponowanie(tablica,tab);
  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  printf("czas CPU: %f \n", elapsed_secs);

}
