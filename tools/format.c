/*
	simple script, used for formatting level data,
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>	

#define WIDTH  32
#define HEIGHT 26
#define SIZE (WIDTH * HEIGHT)
#define META_WIDTH  16
#define META_HEIGHT 13
#define META_SIZE (META_WIDTH * META_HEIGHT) // number of metatiles in the compressed canvas
#define MAX_UNIQUE 256 

typedef struct {
  uint8_t t1;
  uint8_t t2;
  uint8_t b1;
  uint8_t b2;
} Metatile;

// array of match structs
struct {
	size_t length;
	size_t index;
} longest[META_SIZE];

// returns number of consecutive equal bytes for lzss
static size_t cmp(uint8_t const *const a, uint8_t const *const b, size_t len) {
	for (size_t i = 0; i < len; i++) {
		if (a[i] != b[i]) {
			return i;
		}
	}
	return len;
}

// get the index of the metatile in the list of unique metatiles
int getMetatileIndex(Metatile m, Metatile unique[], int uniqueCount) {
    for (int i = 0; i < uniqueCount; i++) {
        Metatile u = unique[i];
        if (m.t1 == u.t1 && m.t2 == u.t2 &&
            m.b1 == u.b1 && m.b2 == u.b2) {
            return i; // found the ID
        }
    }
    return -1; // should never happen if map was built from unique[]
}

int main() {
  char line[1024];            // max line size when reading from file
  uint8_t input[SIZE];

	int index = 0;

  Metatile mTiles[MAX_UNIQUE];
  Metatile mMap[META_SIZE];

	FILE *fptr = fopen("canvas.asm", "r");
	
	if (!fptr) {
		fprintf(stderr, "couldn't find/open the file\n");
		return 1;
	}
	
	// throw away the first line (filename)
	fgets(line, sizeof(line), fptr);

  for (int row = 0; row < HEIGHT * 2; row++) { // read file line by line
    if (!fgets(line, sizeof(line), fptr)) {
			fprintf(stderr, "not enough lines\n");
      return 1;
    }
    
		// only grab the numbers
    for (char *p = line; *p;) {
      if (*p++ == '$') {
        input[index++] = (uint8_t)strtol(p, NULL, 16); // and store them in the matrix
      }
		}
	}
  
	// make sure we got all we needed
	if (index != SIZE) {
    fprintf(stderr, "sumthin fucked up, %d index != %d size\n", index, SIZE);
		return 1;
	}
  
  // create an index of metatiles being used in the current canvas
	int mIndex = 0;
	for(int mRow = 0; mRow < META_HEIGHT; mRow++) {
    for(int mCol = 0; mCol < META_WIDTH; mCol++) {
      
      int row = mRow * 2;
			int col = mCol * 2;
      
			mMap[mIndex].t1 = input[row * WIDTH + col];
			mMap[mIndex].t2 = input[row * WIDTH + col + 1];
			mMap[mIndex].b1 = input[(row + 1) * WIDTH + col];
			mMap[mIndex].b2 = input[(row + 1 )* WIDTH + col + 1];
      
			mIndex++;
		}
	}

  int uniqueCount = 0;
  for (int i = 0; i < META_SIZE; i++) {
    Metatile m = mMap[i];
    int found = 0;

    for (int j = 0; j < uniqueCount; j++) {
      Metatile u = mTiles[j];
      if (m.t1 == u.t1 && m.t2 == u.t2 &&
          m.b1 == u.b1 && m.b2 == u.b2) {

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

  // print result in column major order
  for (int col = 0; col < META_WIDTH; col++) {
      printf("\n");
      for (int row = 0; row < META_HEIGHT; row++) {

          int index = row * META_WIDTH + col;
          int id = getMetatileIndex(mMap[index], mTiles, uniqueCount);
        
          printf("%02X", id + 1); // 1 based to prevent end of stream
					
          if (row < META_HEIGHT - 1) printf(", ");
      }
  }
 return 0; 
}
/*
  // 8bit array of max size initialized to zero
	uint8_t input[META_SIZE] = {0};


  //fills in array with characters from stdin

  // fills input with data
	size_t length = fread(input, 1, META_SIZE, stdin);
	if (length != META_SIZE) {
		printf("length != expected size");
		return 1;
	}

	// find longest matches
  
	// look back 256 times to find the biggest match
	for (unsigned lookBack = 1; lookBack <= 256; lookBack++) {
        
		// i is the index of the pice of data we are looking at in the array
		for (size_t i = lookBack; i < length; i++) {

      // find the ammount of matching bytes starting from lookBack
			// skip through the matches then start analyzing again
			for (size_t len = cmp(input + i, input + i - lookBack, length - i); len > 0; len--, i++) {

				if (len > longest[i].length) {
					longest[i].length = len;
					longest[i].index = lookBack;
				}
			}
		}
	}

	// spit out compressed format
	setvbuf(stdout, NULL, _IOFBF, 0);

	for (size_t i = 0; i < length; ) {

		// count the ammount of consecutively unencoded litterals, up to 127
		size_t literals = 0;
		for (literals = 0; i < length && literals < 128; i++, literals++) {
			if (longest[i].length > 2) {
				break;
			}
		}

		// command byte containing the ammount of conecutive litterals
		putchar(256 - literals);
		// ouput all the conecutive litterals
		fwrite(input + i - literals, 1, literals, stdout);

		if (longest[i].length >= 2) {
			size_t matchLength = longest[i].length;
			if (matchLength > 128) {
				matchLength = 128;
			}

			// commant byte, length of the match 
			putchar(matchLength - 1);
			// command byte, how far back the start of the match is
			putchar((i - longest[i].index) & 0xff);
			i += matchLength;
		}
	}

	// end of stream flag
	putchar(0);
	fflush(stdout);
	return ferror(stdout);
}
	*/