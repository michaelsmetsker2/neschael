/*
	script for formatting output from famitracker

	built with gcc -Wall -o formatSong formatSong.c
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINES 4096
#define MAX_LINE_LEN 1024

typedef struct {
    int type;
    int loopPoint;
    int arpType;
    int index;
    int values[252]; // 252 is max ammount of macro values in famitracker
    int valueCount;
} Macro;

typedef struct {
	int id;
	int index;
	int volume;
	int arpeggio;
	int pitch;
	int duty;
	char name[256]

} Instrument;


int main(int argc, char *argv[]) {
	
	Macro volume_macros[256];
	Macro arpeggio_macros[256];
	Macro pitch_macros[256];
	Macro duty_macros[256];
	
	Macro *macro_arrays[5];
	macro_arrays[0] = volume_macros;
	macro_arrays[1] = arpeggio_macros;
	macro_arrays[2] = pitch_macros;
	macro_arrays[3] = NULL;
	macro_arrays[4] = duty_macros;

	int instrument_count;
	Instrument instruments[256];


	int macro_counts[5] = {0}; // maps to vol, arp, pitch, NULL, duty

	if (argc != 2) {
	fprintf(stdout, "no file specified\n");
	return 1;
	}
	
	// open the file
	FILE *fptr = fopen(argv[1], "r");
	if (!fptr) {
		fprintf(stderr, "couldn't find/open the given file\n");
		return 1;
	}
	
	char *lines[MAX_LINES];
	int lineCount = 0;

	// copy file to heap
	char line[MAX_LINE_LEN] = {0};
	while (fgets(line, sizeof(line), fptr)) {
		lines[lineCount++] = strdup(line);
	}
	fclose(fptr);

	// parse line by line
	for (int i = 0; i < lineCount; i++) {
		// tokenize lines by whitespace
		char *token = strtok(lines[i], " \t\n");
		while (token) {

				if (strcmp(token, "MACRO") == 0) {
					Macro mac = {0};

					mac.type      = atoi(strtok(NULL, " \t\n"));
					strtok(NULL, " \t\n"); // skip id, as the id is the position in its array
					mac.loopPoint = atoi(strtok(NULL, " \t\n"));
					strtok(NULL, " \t\n"); // skip release as it is not supported
					mac.arpType   = atoi(strtok(NULL, " \t\n")); 

					strtok(NULL, ":");
					
					// store list of values
					token = strtok(NULL, " \t\n");
					while (token) {

						mac.values[mac.valueCount++] = atoi(token);
						token = strtok(NULL, " \t\n");
					}

					// store the macro in the correct array, and set its index in that array
					mac.index = macro_counts[mac.type];
					macro_arrays[mac.type][macro_counts[mac.type]++] = mac;

				} else if (strcmp(token, "INST2A03") == 0) {
					Instrument inst = {0};
					strtok(NULL, " \t\n"); // skip id, as id maps to the position in the array
					inst.volume   = atoi(strtok(NULL, " \t\n"));
					inst.arpeggio = atoi(strtok(NULL, " \t\n"));
					inst.pitch    = atoi(strtok(NULL, " \t\n"));
					strtok(NULL, " \t\n"); // skip high pitch, not supported by engine
					inst.duty     = atoi(strtok(NULL, " \t\n"));

					strcpy(inst.name, "test"); // TODO

					instruments[instrument_count++] = inst;


				} else if (strcmp(token, "TRACK") == 0) {

				} else if (strcmp(token, "ORDER") == 0) {

				} else if (strcmp(token, "PATTERN") == 0) {

				} else if (strcmp(token, "ROW") == 0) {

				}

				// advance to the next token
				token = strtok(NULL, " \t\n");
		}
	}


	
	return 0;
}