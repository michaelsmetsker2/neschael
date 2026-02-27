/*
	simple script, used for formatting level data,
	args:
	tile csv relative filepath
	attr csv relative filepath
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>	

#define LINE_SIZE 163840 // set and forget, increas if not enough

#define META_WIDTH  16
#define META_HEIGHT 13
#define META_SIZE (META_WIDTH * META_HEIGHT) // number of metatiles in the compressed canvas
#define MAX_UNIQUE 256 

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

void lzss(const uint8_t *input, FILE *out) {

	memset(longest, 0, sizeof(longest)); // Clear previous compression metadata
  uint8_t output[META_SIZE * 2] = {0}; // Increase size to handle literal overhead

	// look back 256 times to find the biggest match
	for (unsigned lookBack = 1; lookBack <= 256; lookBack++) {
		
		// i is the index of the pice of data we are looking at in the array
		for (size_t i = lookBack; i < META_SIZE; i++) {
			
			// find the ammount of matching bytes starting from lookBack
			// skip through the matches then start analyzing again
			for (size_t len = cmp(input + i, input + i - lookBack, META_SIZE - i); len > 0; len--, i++) {
				
				if (len > longest[i].length) {
					longest[i].length = len;
					longest[i].index = i - lookBack; // index of the start of the match in decompressed data
				}
			}
		}
	}

	size_t outputIndex = 0;

	// add compressed data to ouput array
	for (size_t i = 0; i < META_SIZE;) {
		
		if (longest[i].length > 2) {
			output[outputIndex++] = longest[i].length; // 2 - 128, works as command byte
			output[outputIndex++] = longest[i].index;
			
			i += longest[i].length;
		} else {

			// add the ammount of consecutively literals
			size_t literals = 0;
			for (literals = 0; i < META_SIZE && literals < 128; i++, literals++) {
				if (longest[i].length > 2) {
					break;
				}
			}

			if (literals) {
				output[outputIndex++] = 256 - literals;

				for (size_t l = 0; l < literals; l++) {
					output[outputIndex++] = input[i - literals + l];
				}
			}
		}
	}

	// print and format output
	size_t prindex = 0; // print index
	
	while (prindex < outputIndex) {
		if (prindex % 16 == 0) {
			fprintf(out, "\n  .BYTE "); // start of line
		}

		fprintf(out, "$%02X", output[prindex++]);

		if (prindex % 16 == 0) {
			fprintf(out, " ");
		} else {
			fprintf(out, ", ");
		}
	}
	fprintf(out, "$00\n"); // end of stream

	return;
}

int main(int argc, char *argv[]) {
	if (argc != 3) {
		fprintf(stdout, "see file header for usage\n");
		return 0;
	}

	// ammount of nametables in the file
	uint8_t nametableCount = 0;
	// max line size when reading file
	char line[LINE_SIZE] = {0};
	
	// open tile file
	FILE *tileFile = fopen(argv[1], "r");
	if (!tileFile) {
		fprintf(stderr, "couldn't open/find tile file");
		return 1;
	}
	
	{ // find the ammount of nametables
		fgets(line, sizeof(line), tileFile);
		char *tileken = strtok(line, ",");
		int tokenCount = 0;
		while (tileken) {
			tokenCount++;
			tileken = strtok(NULL, ",");   // advance
		}

		if (tokenCount % 16 != 0) {
			fprintf(stderr, "file width doesn't allign with nametables, must be divisible by 16");
			return 1;
		}

		nametableCount = tokenCount / 16;
		rewind(tileFile);
	}
	
	// read tile data ================================================================================================
	uint8_t (*tileData)[META_SIZE];
	tileData = malloc(nametableCount * sizeof(*tileData)); // maloc nametables
	
	uint8_t rowIndex = 0;
	while (fgets(line, sizeof(line), tileFile)) { // increment though lines

		char *tileken = strtok(line, ",");

		for (uint8_t nt = 0; nt < nametableCount; nt++) { // loop through all nametables in the row			
			for (uint8_t tileIndex = 0; tileIndex < META_WIDTH; tileIndex++) { // loop through each piece of data
				int tile = atoi(tileken);

				tileData[nt][META_HEIGHT * tileIndex + rowIndex] = tile; // store in column major order

				tileken = strtok(NULL, ",");   // advance token
			}
		}	
		
		rowIndex++;
	}
	fclose(tileFile);

	// parse attribute data ====================================================================================

	uint8_t (*attrData)[8 * 7];
	attrData = malloc(nametableCount * sizeof(*attrData)); // maloc nametables


	FILE *attrFile = fopen(argv[2], "r");
	
	rowIndex = 0;
	while(fgets(line, sizeof(line), attrFile)) {
		
		uint8_t attrByte[LINE_SIZE / 2] = {0};

		// tokenize and put the stuff into nibbles
		char *token = strtok(line, ",");
		
		for (int attrIndex = 0; attrIndex < nametableCount * META_WIDTH / 2; attrIndex++) {
			
			uint8_t attrLeft = (uint8_t)atoi(token);
			attrLeft = attrLeft << 2; // shift two bits left for top part of nibble
			token = strtok(NULL, ","); // increment token
			uint8_t attrRight = (uint8_t)atoi(token);
			token = strtok(NULL, ","); // increment token
			
			uint8_t attrNibble = attrLeft | attrRight; // turn into nibble

			if (rowIndex % 2 == 0) { // bottom
				attrByte[attrIndex] |= attrNibble;				

			} else { // top
				attrByte[attrIndex] |= (attrNibble << 4); // bit shift to top nibble and overwrite old
			}
		}

		if (rowIndex % 2 == 0) { // bottom
			
			// store in column-major order

			for (uint8_t nt = 0; nt < nametableCount; nt++) {
				for(uint8_t col = 0; col < 8 ; col++) {
					attrData[nt][col * 7 + rowIndex] = attrByte[col + nt * 8 * 7];
				}
			} 
		}

		rowIndex++;
	}
	fclose(attrFile);

	
	
	// print format and LZSS ==================================================================================================================
  FILE *out = fopen("level.s", "w");
  if (!out) {
		fprintf(stderr, "counldn't open output file");
    return 1;
  }
	
  // print header
  fprintf(out, ";\n; neschael\n; data/levels/****.s\n;\n; file generated by tools/formatCanvas.c\n; contains level data\n;\n\n");
  fprintf(out, ".EXPORT LEVELNAME\n\n");
  
  // lookup table
  fprintf(out, "LEVELNAME:\n\t.WORD background_index, attribute_index, spawn_stream\n");
	fprintf(out, "\t.BYTE $00, $00 ; high byte of player starting X and Y\n");
	fprintf(out, "\t.BYTE $%02X ; length of background, zero based\n\n", nametableCount);
	
	fprintf(out, "background_index:\n\t.WORD ");
  for (int i = 0; i < nametableCount; i++) {
		if (i) {
			fprintf(out, ", ");
    }
    fprintf(out, "background_%i", i);
  }
	
	fprintf(out, "\nattribute_index:\n\t.WORD ");
	for (int i = 0; i < nametableCount; i++) {
		if (i) {
			fprintf(out, ", ");
    }
    fprintf(out, "attrib_%i", i);
  }
	
	fprintf(out, "\nspawn_stream\n\t.WORD spawn_stream ; todo\n"); // todo
	
	for(uint8_t nt = 0; nt < nametableCount; nt++) {
		// print tile data
		fprintf(out, "\nbackground_%i:", nt);
		lzss(tileData[nt], out);
	
		// print attr data
		fprintf(out, "\nattrib_%i:", nt);
		lzss(attrData[nt], out);

		//print spawn stream data
	}

	/*
	for (int i = 1; i < 7 * 8; i++) {
		printf("%02X, " , attrData[0][i-1]);
		if (i % 7 == 0) {
			printf("\n"); 
		}
	}
	*/
	
	return 0;
}