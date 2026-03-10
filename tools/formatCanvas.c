/*
	simple script, used for formatting level data,
	args:
		<*_tiles.csv> relative filepath

	no underscores in file path

	tested on linux, built with:
	gcc -Wall -o formatCanvas formatCanvas.c
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
#define ATTR_SIZE 56

#define debug 0

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

/**
 * lzss compresses data
 * 
 * @param input     - pointer to array of uint8 data
 * @param out       - output stream to print the data to 
 * @param inputSize - size of the input array
 */
void lzss(const uint8_t *input, FILE *out, uint8_t inputSize) {

	memset(longest, 0, sizeof(longest)); // Clear previous compression metadata
  uint8_t output[META_SIZE * 2] = {0}; // Increase size to handle literal overhead

	// look back 256 times to find the biggest match
	for (unsigned lookBack = 1; lookBack <= 256; lookBack++) {
		
		// i is the index of the pice of data we are looking at in the array
		for (size_t i = lookBack; i < inputSize; i++) {
			
			// find the ammount of matching bytes starting from lookBack
			// skip through the matches then start analyzing again
			for (size_t len = cmp(input + i, input + i - lookBack, inputSize - i); len > 0; len--, i++) {
				
				if (len > longest[i].length) {
					longest[i].length = len;
					longest[i].index = i - lookBack; // index of the start of the match in decompressed data
				}
			}
		}
	}

	size_t outputIndex = 0;

	// add compressed data to ouput array
	for (size_t i = 0; i < inputSize;) {
		
		if (longest[i].length > 2) {
			output[outputIndex++] = longest[i].length; // 2 - 128, works as command byte
			output[outputIndex++] = longest[i].index;
			
			i += longest[i].length;
		} else {

			// add the ammount of consecutively literals
			size_t literals = 0;
			for (literals = 0; i < inputSize && literals < 128; i++, literals++) {
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

	// print null terminator
	if (prindex % 16 == 0) {
		fprintf(out, "\n\t.BYTE $00\n");
	} else {
		fprintf(out, "$00 \n");
	}

	return;
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stdout, "see file header for usage\n");
		return 0;
	}
	
	// ammount of nametables in the file
	uint8_t nametableCount = 0;
	// max line size when reading file
	char line[LINE_SIZE] = {0};
	
	// find other filenames based on the tile file name
	char *underscore = strchr(argv[1], '_');
	if (!underscore) {
		fprintf(stdout, "invalid filename\n");
		return 1;
	}	
	
	int nameLen = underscore - argv[1];
	
	char attrFilename[256];
	char spawnFilename[256];
	 
	strncpy(attrFilename, argv[1], nameLen);
	attrFilename[nameLen] = '\0';
	strcat(attrFilename, "_attribute.csv");
	strncpy(spawnFilename, argv[1], nameLen);
	spawnFilename[nameLen] = '\0';
	strcat(spawnFilename, "_spawn.csv");

	// =============================================== open tile file ============================================================
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

	FILE *attrFile = fopen(attrFilename, "r");
	if (!attrFile) {
		fprintf(stderr, "couldn't open/find attribute file\n");
		return 1;
	}	

	// line of output data, initialized to zero
	uint8_t attrByte[LINE_SIZE / 2] = {0};

	rowIndex = 0;
	while(fgets(line, sizeof(line), attrFile)) {
		
		// tokenize attr data
		char *token = strtok(line, ",");
		
		// proccess a row of input data and assign it to the top or bottom bytes of the output row
		for (int attrIndex = 0; attrIndex < nametableCount * (META_WIDTH / 2); attrIndex++) {
			
			
			uint8_t attrLeft = (uint8_t)atoi(token);
			token = strtok(NULL, ","); // increment token
			uint8_t attrRight = (uint8_t)atoi(token);
			token = strtok(NULL, ","); // increment token
			
			// shift left to combine with left bit
			uint8_t attrNibble = (attrRight << 2) | attrLeft; // turn into nibble
			
			if (rowIndex % 2 == 0) { // top
				attrByte[attrIndex] |= (attrNibble << 4);				

			} else { // bottom, clobbers old row and shifts left to be dop nibble
				attrByte[attrIndex] = attrNibble;
			}
		}

		if (rowIndex % 2 == 0) { // once a bottom row is proccessed, add it to the data

			#if debug
			for(uint8_t i = 0; i < (nametableCount * 8); i++) {
				fprintf(stdout, ", %02X", attrByte[i]);
			}
			fprintf(stdout, "\n");
			#endif

			// store in column-major order
			for (uint8_t nt = 0; nt < nametableCount; nt++) {
				for(uint8_t col = 0; col < 8 ; col++) {
					attrData[nt][col * 7 + (rowIndex / 2)] = attrByte[col + nt * 8];
				}
			}
		}

		rowIndex++;
	}

	#if debug // print in column major order
	printf("\n\n\n\n");
	for (int i = 0; i < nametableCount; i++) {
		for (int col = 0; col < 8; col++) {
			for (int row = 0; row < 7; row++) {
				printf(", %02X", attrData[i][col * 7 + row]);
			}
			printf("\n");
		}
		printf("\n");
	}
	#endif

	fclose(attrFile);

	// parse spawn stream data ====================================================================================
	FILE *spawnFile = fopen(spawnFilename, "r");
	if (!spawnFile) {
		fprintf(stderr, "couldn't open/find spawn file\n");
		return 1;
	}

	// what metacolumns have an entity
	uint8_t *spawnColumns = calloc(nametableCount * 2, sizeof(uint8_t));

	while(fgets(line, sizeof(line), spawnFile)) {
		
		char *token = strtok(line, ",");

		// loop through nametables
		for (int nt = 0; nt < nametableCount; nt++) {

			uint8_t *low  = &spawnColumns[nt * 2];
			uint8_t *high = &spawnColumns[nt * 2 + 1];

			// loop through 16 metacolumns
			for (int colIndex = 0; colIndex < META_WIDTH; colIndex++) {
				
				uint8_t entityId = (uint8_t)atoi(token); 
				if (entityId != 0xFF) {
					
					uint8_t colBit = 1;
					
					// bit shift one by colIndex mod 8
					colBit = colBit << (colIndex % 8);

					// or onto the column
					if (colIndex < 8) {
						*low |= colBit;
					} else {
						*high |= colBit;
					}

				}

				token = strtok(NULL, ","); // increment token

			}
		}
	}

	fclose(spawnFile);	
	
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
	fprintf(out, "\t.BYTE $%02X ; length of background, zero based\n\n", nametableCount - 1);
	
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
	
	fprintf(out, "\nspawn_stream:\n\t.WORD ");
	for (int i = 0; i < nametableCount; i++) {
		if (i) {
			fprintf(out, ",");
		}
		fprintf(out, "stream_%i", i);
	}

	fprintf(out, "\n");
	// print data =============================================

	for(uint8_t nt = 0; nt < nametableCount; nt++) {
		// print tile data
		fprintf(out, "\nbackground_%i:", nt);
		lzss(tileData[nt], out, META_SIZE);
	
		// print attr data
		fprintf(out, "\nattrib_%i:", nt);
		lzss(attrData[nt], out, ATTR_SIZE);

		//print spawn stream data
		fprintf(out, "\nstream_%i:", nt);
		fprintf(out, "\n\t.BYTE $%02X, $%02X\n", spawnColumns[nt * 2], spawnColumns[nt * 2 + 1]);
	}
	
	return 0;
}