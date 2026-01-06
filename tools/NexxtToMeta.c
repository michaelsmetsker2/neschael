#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define WIDTH  32
#define HEIGHT 28
#define SIZE (WIDTH * HEIGHT)
#define META_WIDTH  16
#define META_HEIGHT 14
#define META_SIZE (META_WIDTH * META_HEIGHT)

#define MAX_UNIQUE 256

typedef struct {
  uint8_t t1;
  uint8_t t2;
  uint8_t t3;
  uint8_t t4;
} Metatile;

int getMetatileIndex(Metatile m, Metatile unique[], int uniqueCount) {
    for (int i = 0; i < uniqueCount; i++) {
        Metatile u = unique[i];
        if (m.t1 == u.t1 && m.t2 == u.t2 &&
            m.t3 == u.t3 && m.t4 == u.t4) {
            return i; // found the ID
        }
    }
    return -1; // should never happen if map was built from unique[]
}



int main() {
  char line[1024];
  uint8_t matrix[SIZE];
  int index = 0;

  Metatile mTiles[MAX_UNIQUE];
  Metatile mMap[SIZE / 4];
  Metatile mMapT[SIZE /4];


  printf("Gimme your data\n");

  for (int row = 0; row < HEIGHT; row++) { // read one line of data (row)
    if (!fgets(line, sizeof(line), stdin)) {
      fprintf(stderr, "not enough lines\n");
      return 1;
    }
    
    int count = 0;
    for (char *p = line; *p && count < WIDTH; p++) {
      if (*p == '$') {
        p++;
        matrix[index++] = (uint8_t)strtol(p, NULL, 16);
        count++;
      }
      p++;
  }

  if (index != SIZE) {
    fprintf(stderr, "sumthin fucked up, %d index != %d size\n", index, SIZE);
    return 1;
  }


  int mIndex = 0;
  for(int mRow = 0; mRow < HEIGHT / 2; mRow++) {
    for(int mCol = 0; mCol < WIDTH / 2; mCol++) {

      int row = mRow * 2;
      int col = mCol * 2;

      mMap[mIndex].t1 = matrix[row * WIDTH + col];
      mMap[mIndex].t2 = matrix[row * WIDTH + col + 1];
      mMap[mIndex].t3 = matrix[(row + 1) * WIDTH + col];
      mMap[mIndex].t4 = matrix[(row + 1 )* WIDTH + col + 1];

      mIndex++;
    }
  }

  int uniqueCount = 0;
  for (int i = 0; i < SIZE / 4; i++) {
    Metatile m = mMap[i];
    int found = 0;

    for (int j = 0; j < uniqueCount; j++) {
      Metatile u = mTiles[j];
      if (m.t1 == u.t1 && m.t2 == u.t2 &&
          m.t3 == u.t3 && m.t4 == u.t4) {

          found = 1;
          break;
      }  
    }

    if (!found) {
      if (uniqueCount >= MAX_UNIQUE) {
        fprintf(stderr, "Too many unique metatiles\n");
        return 1;
      }
      mTiles[uniqueCount++] = m;
    }



  }

  // put in column major order
  for (int row = 0; row < HEIGHT / 2; row++) {
    for (int col = 0; col < WIDTH / 2; col++) {

      mMapT[col * HEIGHT / 2 + row] = mMap[row * WIDTH / 2 + col];


    }
  }

  
  // print result
  for (int row = 0; row < HEIGHT / 2; row++) {
      printf(".byte ");
      for (int col = 0; col < WIDTH / 2; col++) {
          int idx = col * HEIGHT / 2 + row; // column-major
          int id = getMetatileIndex(mMapT[idx], mTiles, uniqueCount);
          printf("$%02X", id);
          if (col < WIDTH / 2 - 1) {
            printf(", ");
          }
      }
      printf("\n");
  }
  
  return 0;
  }
}