/*
	simple script, used for formatting level data,
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
//#include <stdlib.h>
//#include <ctype.h>	

#define MAX_METATILES 256
#define LINE_SIZE 16
#define SIZE (32 * 32)

int main() {
 
  uint8_t tiles[SIZE] = {0};
  uint8_t collision[SIZE] = {0};
  
  char line[1024];            // max line size when reading from file
	
  FILE *fptr = fopen("../data/tiles/raw/metas.asm", "r");
	
	if (!fptr) {
    fprintf(stderr, "couldn't find/open metas.asm\n");
		return 1;
	}
	
	// throw away the first line (filename)
  fgets(line, sizeof(line), fptr);

  int index = 0;
  while (fgets(line, sizeof(line), fptr)) {  
		
    // only grab the numbers
    for (char *p = line; *p;) {
      if (*p++ == '$') {
        tiles[index++] = (uint8_t)strtol(p, NULL, 16); // and store them in the matrix
      }
		}
	}
  fclose(fptr);  

  // get collision date from tiled file
  FILE *collptr = fopen("./tiled/metas.tsx", "r");

  if (!collptr) {
    fprintf(stderr, "couldn't find/open metas.tsx\n");
    return 1;
  }

  index = 0;
  while (fgets(line, sizeof(line), collptr)) {

    char *p = line;

    if ((p = strstr(p, "value=\"")) != NULL) {

      p += 7; // increment past value="
      collision[index++] = (uint8_t)strtol(p, NULL, 10);
    }
  }
  fclose(collptr);


  // print and format the data in the correct file

  //print header

  // print lookup table

  // loop through metatiles



	return 0;
}