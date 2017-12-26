#include <stdio.h>
#include <math.h>
#include <ctime>

using namespace std;

int transponowanie(){
  clock_t begin = clock();
  int const size(1000);
  static double tablica[size][size];
  static double tab[size][size];
  for(int i=0; i<size;i++){
    for(int j=0; j<size;j++){
      tablica[i][j]=i*size+j+1;
    }
  }
  printf("przed: 1:%f ", tablica[0][1]);
  printf("2:%f \n", tablica[1][0]);
  for(int i=0; i<size;i++){
    for(int j=0; j<size;j++){
      tab[j][i]=tablica[i][j];
    }
  }
  printf("po: 1:%f ", tab[0][1]);
  printf("2:%f \n", tab[1][0]);
  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  printf("czas CPU: %f \n", elapsed_secs);
  return 1;
}




int main(void){
  transponowanie();
}
