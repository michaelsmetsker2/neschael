/*
	simple script, used for formatting level data,
	args:
		<*_tiles.csv> relative filepath

	no underscores in file path

	tested on WSL, built with:
	gcc -Wall -o formatCanvas formatCanvas.c
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>	

#define LINE_SIZE 163840 // set and forget, increas if not enough

#define META_WIDTH  16
#define META_HEIGHT 12
#define META_SIZE (META_WIDTH * META_HEIGHT) // number of metatiles in the compressed canvas
#define MAX_UNIQUE 256 
#define ATTR_WIDTH 8
#define ATTR_HEIGHT 6
#define ATTR_SIZE (ATTR_WIDTH * ATTR_HEIGHT)

#define debug 0

// array of match structs
struct {
	size_t length;
	size_t index;
} longest[META_SIZE + ATTR_SIZE];

typedef struct EntityNode {
	uint8_t column;
	uint8_t entityId;
	uint8_t yPos;
	struct EntityNode* next;
} EntityNode;

// linked list implementation for entities
typedef struct {
		EntityNode* head;
} EntityList;

// FIXME this may be broken
void insertEntityOrdered(EntityList* list, uint8_t col, uint8_t id, uint8_t yPos) {
	EntityNode* newNode = malloc(sizeof(EntityNode));
	newNode->column = col;
	newNode->entityId = id;
	newNode->yPos = yPos;

	if (!list->head || id < list->head->entityId) {
		newNode->next = list->head;
		list->head = newNode;
		return;
	}

	EntityNode* current = list->head;
	while (current->next && current->next->entityId < id) {
		current = current->next;
	}

	newNode->next = current->next;
	current->next = newNode;
}

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
 * lzss compresses data and prints
 * 
 * @param input     pointer to array of uint8 data
 * @param out       output stream to print the data to 
 * @param inputSize size of the input array
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

/**
 * finds the ammount of nametables in the level then parses and compresses level data into metatiles
 * @param outputData      will be filled with tile data compressed to metatiles
 * @param nametableCount  will be updated with the ammount of nametables in teh level
 * @param filename        name of the tile data file
 * 
 * @return 0 on succuss
 */
int parseTiles(uint8_t (**outputData)[META_SIZE], uint8_t *nametableCount, const char *filename) {

	FILE *tileFile = fopen(filename, "r");
	if (!tileFile) {
		return 1;
	}
	
	// max line size when reading file
	char line[LINE_SIZE] = {0};

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
	
	*nametableCount = tokenCount / 16;
	rewind(tileFile);

	*outputData = malloc(*nametableCount * sizeof(**outputData)); // maloc nametables

	// read tile data
	uint8_t rowIndex = 0;
	while (fgets(line, sizeof(line), tileFile)) { // increment though lines

		char *tileken = strtok(line, ",");

		for (uint8_t nt = 0; nt < *nametableCount; nt++) { // loop through all nametables in the row			
			for (uint8_t tileIndex = 0; tileIndex < META_WIDTH; tileIndex++) { // loop through each piece of data
				int tile = atoi(tileken);

				(*outputData)[nt][META_HEIGHT * tileIndex + rowIndex] = tile; // store in column major order

				tileken = strtok(NULL, ",");   // advance token
			}
		}	
		
		rowIndex++;
	}
	fclose(tileFile);
	return 0;
}

/**
 * reads the attribute data file and compresses it into nes ppu data 
 * @param outputData     extracted and compressed attribute data array
 * @param nametableCount ammount of nametables in the current level
 * @param filename       filename of the file to parse
 * 
 * @return 0 on success
 */
int parseAttr(uint8_t (*outputData)[ATTR_SIZE], const uint8_t nametableCount, const char *filename) {
	// character array to hold raw data from the file
	char line[LINE_SIZE] = {0};

	FILE *attrFile = fopen(filename, "r");
	if (!attrFile) {
		return 1;
	}	

	// line of output data, initialized to zero
	uint8_t attrByte[LINE_SIZE / 2] = {0};

	uint8_t rowIndex = 0;
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
			
			if (rowIndex % 2 == 0) { // top, clobbers old row
				attrByte[attrIndex] = attrNibble;
				
			} else { // bottom
				attrByte[attrIndex] |= (attrNibble << 4);
			}
		}

		if (rowIndex % 2 != 0) { // once a bottom row is proccessed, add it to the data

			// store in column-major order
			for (uint8_t nt = 0; nt < nametableCount; nt++) {
				for(uint8_t col = 0; col < ATTR_WIDTH ; col++) {
					outputData[nt][col * ATTR_HEIGHT + (rowIndex / 2)] = attrByte[col + nt * ATTR_WIDTH];
				}
			}
		}
		rowIndex++;
	}

	#if debug // print in column major order
	printf("\n\n\n\n");
	for (int i = 0; i < nametableCount; i++) {
		for (int col = 0; col < ATTR_WIDTH; col++) {
			for (int row = 0; row < ATTR_HEIGHT; row++) {
				printf(", %02X", attrData[i][col * ATTR_HEIGHT + row]);
			}
			printf("\n");
		}
		printf("\n");
	}
	#endif

	fclose(attrFile);
	return 0;
}

/**
 * parses entity data and populates both spawn columns and spawn streams
 * @param spawnStream array of ordered lists containing entity data
 * @param spawnColumns 2 bytes per nametable with each bit representing if a metacol holds and entity
 * @param nametableCount ammount of nametables in the level
 * @param filename name of the entity layer file
 * 
 * @return 0 on success
 */
int parseEntities(EntityList *spawnStream, uint8_t *spawnColumns, const uint8_t nametableCount, const char *filename) {

	// open file
	FILE *spawnFile = fopen(filename, "r");
	if (!spawnFile) {
		return 1;
	}

	// character array to hold raw data from the file
	char line[LINE_SIZE] = {0};

	// loop through the files lines
	uint8_t lineCount = 0;
	while(fgets(line, sizeof(line), spawnFile)) {
		char *token = strtok(line, ",");

		// loop through nametables
		for (int nt = 0; nt < nametableCount; nt++) {

			uint8_t *low  = &spawnColumns[nt * 2];
			uint8_t *high = &spawnColumns[nt * 2 + 1];

			for (int colIndex = 0; colIndex < META_WIDTH; colIndex++) {
				
				// check if an entity is present
				uint8_t entityId = (uint8_t)atoi(token); 
				if (entityId != 0xFF) {
					
					// add entity into the spawnstream
					insertEntityOrdered(&spawnStream[nt], colIndex, entityId, lineCount);
					
					// bit shift one by colIndex mod 8
					uint8_t colBit = 1;
					colBit = colBit << (colIndex % 8);

					// bitwise or onto the column
					if (colIndex < 8) {
						*low |= colBit;
					} else {
						*high |= colBit;
					}
				}

				token = strtok(NULL, ","); // increment token
			}
		}
		lineCount++;
	}

	fclose(spawnFile);	
	return 0;

}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stdout, "./formatCanvas <tiles.csv>\n");
		return 0;
	}
	
	// find other filenames based on the tile file name
	char *underscore = strchr(argv[1], '_');
	if (!underscore) {
		fprintf(stdout, "invalid filename\n");
		return 1;
	}	
	
	int nameLen = underscore - argv[1];
	char attrFilename[75]; //arbitrary size
	char spawnFilename[75];
	
	strncpy(attrFilename, argv[1], nameLen);
	attrFilename[nameLen] = '\0';
	strcat(attrFilename, "_attribute.csv");
	strncpy(spawnFilename, argv[1], nameLen);
	spawnFilename[nameLen] = '\0';
	strcat(spawnFilename, "_spawn.csv");
	
	// find ammount of nametables in the file and parse tile data
	uint8_t nametableCount = 0;
	uint8_t (*tileData)[META_SIZE] = NULL;
	if (parseTiles(&tileData, &nametableCount, argv[1]) != 0) {
		fprintf(stderr, "error opening or parsing tile file");
		return 1;
	}

	// read level attribute data
	uint8_t (*attrData)[ATTR_SIZE];
	attrData = malloc(nametableCount * sizeof(*attrData)); // maloc nametables
	if (parseAttr(attrData, nametableCount, attrFilename) != 0) {
		fprintf(stderr, "error parsing attribute data or opening file");
		return 1;
	}

	// create and initialize the spawnStream
	EntityList spawnStreams[nametableCount];
	for (int i = 0; i < nametableCount; i++) {
		spawnStreams[i].head = NULL;
	}
	uint8_t *spawnColumns = calloc(nametableCount * 2, sizeof(uint8_t));
	
	// read level entity data
	if (parseEntities(spawnStreams, spawnColumns, nametableCount, spawnFilename) != 0) {
		fprintf(stderr, "error parsing or opening spawn layer");
		return 1;
	}
	
	// print format and LZSS
  FILE *out = fopen("level.s", "w");
  if (!out) {
		fprintf(stderr, "counldn't open output file");
    return 1;
  }
	
  // print header
  fprintf(out, ";\n; neschael\n; data/levels/****.s\n;\n; file generated by tools/formatCanvas.c\n; contains level data\n;\n\n");
  fprintf(out, ".EXPORT LEVELNAME\n\n");
  
  // lookup table
  fprintf(out, "LEVELNAME:\n\t.WORD background_index, spawn_stream\n");
	fprintf(out, "\t.BYTE $00, $00 ; high byte of player starting X and Y\n");
	fprintf(out, "\t.BYTE $%02X ; length of background, zero based\n\n", nametableCount - 1);
	
	fprintf(out, "background_index:\n\t.WORD ");
  for (int i = 0; i < nametableCount; i++) {
		if (i) {
			fprintf(out, ", ");
    }
    fprintf(out, "background_%i", i);
  }
	
	fprintf(out, "\nspawn_stream:\n\t.WORD ");
	for (int i = 0; i < nametableCount; i++) {
		if (i) {
			fprintf(out, ",");
		}
		fprintf(out, "stream_%i", i);
	}

	fprintf(out, "\n");
	// print data

	for(uint8_t nt = 0; nt < nametableCount; nt++) {

		fprintf(out, "\nbackground_%i:", nt);
		// array of combined attr, tile and spawncolumn data
		uint8_t backgroundData[META_SIZE + ATTR_SIZE + 2] = {0};
		memcpy(backgroundData, tileData[nt], META_SIZE);
		memcpy(backgroundData + META_SIZE, attrData[nt], ATTR_SIZE);
		memcpy(backgroundData + META_SIZE + ATTR_SIZE, &spawnColumns[nt * 2], 2);
		// compress and print
		lzss(backgroundData, out, META_SIZE + ATTR_SIZE + 2);
	
		//print spawn stream data
		fprintf(out, "\nstream_%i:\n", nt);

		EntityNode *cur = spawnStreams[nt].head;
		if(cur) { // don't need to preint ind of stream byte if there are no entities in the nametable
			while(cur) {

				// combine both x and y positions into one bytex
				uint8_t posByte = cur->column;
				posByte |= (cur->yPos << 4);

				fprintf(out, "\t.BYTE $%02X, $%02X, $00 ; X: %02u, Y: %02u\n", posByte, cur->entityId, cur->column, cur->yPos);
				cur = cur->next;			
			}
			// end of stream
			fprintf(out, "\t.BYTE $00\n"); 
		}
	}
	
	return 0;
}