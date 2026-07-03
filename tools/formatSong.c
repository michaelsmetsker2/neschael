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
    int values[252]; // 252 is max ammount of macro values in famitracker
    int valueCount;
} Macro;

typedef struct {
	int volume_id;
	int arpeggio_id;
	int pitch_id;
	int duty_id;
	char name[256];
} Instrument;

typedef struct {
	char note[3];
	int instrument;
	char effect[3];
} Note;

// channel patterns that corrospondd with the section of the track
typedef struct {
	int square_1;
	int square_2;
	int triangle;
	int noise;
} Order;

typedef struct {
	Note square_1;
	Note square_2;
	Note triangle;
	Note noise;
} Row;

typedef struct {
	Row rows[256];
	int row_count;
} Pattern;

// music or sfx track
typedef struct {
	int pattern_length;
	int speed;
	int tempo;
	char name[256];
	Order orders[256];
	int order_count;
	Pattern patterns[256];
	int pattern_count;
} Track;


/**
 * removes all invalid characters from a string
 * 
 * @param label pointer to the label to sanitize
 */
void sanitize_label(char *label) {
    const char *allowed = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    int len = strlen(label);

    char *tmp = malloc((len + 2) * sizeof(char));
	// start with an underscore
    tmp[0] = '_';
    int pos = 1;

    for (int i = 0; label[i] != '\0'; i++) {
        if (strchr(allowed, label[i])) {
            tmp[pos++] = label[i];
        }
    }
    tmp[pos] = '\0';

    strcpy(label, tmp);
    free(tmp);
}

/**
 * format the pitch / note part of the note struct
 * 
 * @param str string to format
 */
void format_string(char *str) {
	if (strcmp(str, "...") == 0) {
		// no note
		str[0] = '\0';

	} else if (str[2] == '#') {
		// noise note. convert first char from hex to int
		int val = (int)strtol(&str[0], NULL, 16);
		snprintf(str, 4, "%d", val);

	} else if (str[1] == '#') {
		// sharp - replace # with S
		str[1] = 'S';

	} else if (str[1] == '-') {
		// natural (not sharp or flat), just shift octave left
		str[1] = str[2];
		str[2] = '\0';
	}
}

/**
 * parse the raw note data, format it and put it into a note struct 
 * 
 * @param str string containing note output from famitracker
 * @param out resulting Note struct with correct formatting 
 */
void proccess_note(char *str, Note *out) {
	
	char tmp_note[3];
	char tmp_inst[2];
	char tmp_effect[3];
	
	// split the string
	sscanf(str, " %3s %2s %*s %3s", tmp_note, tmp_inst, tmp_effect );

	//handle note
	format_string(tmp_note);
	strcpy(out->note, tmp_note);

	// handle instrument	
	if (strcmp(tmp_inst, "..") == 0) {
		out->instrument = -1;
	} else {
		out->instrument = (int)strtol(tmp_inst, NULL, 16);
	}

	// handle effect
	strcpy(out->effect, tmp_effect);

}

/**
 * helper for writing macro data tot he output fike
 * 
 * @param out file to output to
 * @param macro macro to write
 * @param isDuty is the macro a duty macro 0 for no 1 for yes 
 * @param offset the start of this macros data's from the start of the instrument
 */
void write_macro(FILE *out, Macro *macro, int isDuty, int offset) {
    fprintf(out, "\t.BYTE ");
	// print out main values
	for (int i = 0; i < macro->valueCount; i++) {
        fprintf(out, "$%02X, ", macro->values[i]);
    }
    if (macro->loopPoint == -1) {
		if (isDuty) {
			fprintf(out, "DUTY_ENV_STOP\n");
		} else {
			fprintf(out, "ENV_STOP\n");
		}
    } else {
		if (isDuty) {
			fprintf(out, "DUTY_ENV_LOOP, $%02X\n", macro->loopPoint + offset);
		} else {
			fprintf(out, "ENV_LOOP, $%02X\n", macro->loopPoint + offset);
		}
    }
	return;
}


int main(int argc, char *argv[]) {
	
	Macro volume_macros[256] = {0};
	Macro arpeggio_macros[256] = {0};
	Macro pitch_macros[256] = {0};
	Macro duty_macros[256] = {0};
	
	Macro *macro_arrays[5];
	macro_arrays[0] = volume_macros;
	macro_arrays[1] = arpeggio_macros;
	macro_arrays[2] = pitch_macros;
	macro_arrays[3] = NULL;
	macro_arrays[4] = duty_macros;
	int macro_counts[5] = {0}; // maps to vol, arp, pitch, NULL, duty

	Instrument instruments[256];
	int instrument_count = 0;

	Track *songs = malloc(256 * sizeof(Track));
	int song_count = 0;
	Track *sfx   = malloc(256 * sizeof(Track));
	int sfx_count = 0;

	// for parsing, points to the current track being read
	Track *current_track = NULL;
	Pattern *current_pattern = NULL;

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
					strtok(NULL, " \t\n"); // skip index as index is position in array
					mac.loopPoint = atoi(strtok(NULL, " \t\n"));
					strtok(NULL, " \t\n"); // skip release as it is not supported
					mac.arpType   = atoi(strtok(NULL, " \t\n")); 
					
					strtok(NULL, " \t\n"); // skip the colon
					// store list of values
					token = strtok(NULL, " \t\n");
					while (token) {
						mac.values[mac.valueCount++] = atoi(token);
						token = strtok(NULL, " \t\n");
					}

					// store the macro in the correct array
					macro_arrays[mac.type][macro_counts[mac.type]++] = mac;

				} else if (strcmp(token, "INST2A03") == 0) {
					Instrument inst = {0};
					strtok(NULL, " \t\n"); // skip id, as id maps to the position in the array
					inst.volume_id   = atoi(strtok(NULL, " \t\n"));
					inst.arpeggio_id = atoi(strtok(NULL, " \t\n"));
					inst.pitch_id    = atoi(strtok(NULL, " \t\n"));
					strtok(NULL, " \t\n"); // skip high pitch, not supported by engine
					inst.duty_id     = atoi(strtok(NULL, " \t\n"));

					token = strtok(NULL, "\"");
					sanitize_label(token);
					strcpy(inst.name, token);
					
					char suffix[8];
					sprintf(suffix, "_%d", instrument_count); // swap `index` for whatever holds the position
					strcat(inst.name, suffix);


					instruments[instrument_count++] = inst;

				} else if (strcmp(token, "TRACK") == 0) {

					Track track = {0};
					track.pattern_length = atoi(strtok(NULL, " \t\n"));
					track.speed 		 = atoi(strtok(NULL, " \t\n"));
					track.tempo			 = atoi(strtok(NULL, " \t\n"));

					token = strtok(NULL, "\"");
					strcpy(track.name, token);
					sanitize_label(track.name);

					// add to either sfx or track list
					if (strncmp(track.name, "_sfx_", 5) == 0) {
						sfx[sfx_count] = track;
						current_track = &sfx[sfx_count++];
					} else {
						songs[song_count] = track;
						current_track = &songs[song_count++];
					}

				} else if (strcmp(token, "ORDER") == 0) {

					Order order = {0};

					strtok(NULL, ":");
					order.square_1 =  atoi(strtok(NULL, " \t\n"));
					order.square_2 =  atoi(strtok(NULL, " \t\n"));
					order.triangle =  atoi(strtok(NULL, " \t\n"));
					order.noise    =  atoi(strtok(NULL, " \t\n"));

					current_track->orders[current_track->order_count++] = order;

				} else if (strcmp(token, "PATTERN") == 0) {
					
					// create a new pattern, set it to current and add it to the current track
					Pattern pattern = {0};
					current_track->patterns[current_track->pattern_count] = pattern;
					current_pattern = &current_track->patterns[current_track->pattern_count++];

				} else if (strcmp(token, "ROW") == 0) {
					
					Row row = {0};

					strtok(NULL, ":"); // skip to the first channel

					token = strtok(NULL, ":");
					proccess_note(token, &row.square_1);
					token = strtok(NULL, ":");
					proccess_note(token, &row.square_2);
					token = strtok(NULL, ":");
					proccess_note(token, &row.triangle);
					token = strtok(NULL, ":");
					proccess_note(token, &row.noise);

					current_pattern->rows[current_pattern->row_count++] = row;
				}

			// advance to the next token
			token = strtok(NULL, " \t\n");
		}
	}

	// file is now parsed and data is placed into structs correctly

	// add silent vol macro
	int silent_vol_idx = macro_counts[0];
    Macro silent_vol = {0};
    silent_vol.loopPoint = -1;
    silent_vol.values[0] = 0; 
    silent_vol.valueCount = 1;
    volume_macros[macro_counts[0]++] = silent_vol;

    // add default arpeggio macro
    int default_arp_idx = macro_counts[1];
    Macro default_arp = {0};
    default_arp.loopPoint = -1;
    default_arp.valueCount = 0; // Arpeggio is explicitly empty by default
    arpeggio_macros[macro_counts[1]++] = default_arp;

    // add flat pitch macro
    int flat_pitch_idx = macro_counts[2];
    Macro flat_pitch = {0};
    flat_pitch.loopPoint = -1;
    flat_pitch.values[0] = 0;
    flat_pitch.valueCount = 1;
    pitch_macros[macro_counts[2]++] = flat_pitch;

    // add default duty macro
    int default_duty_idx = macro_counts[4];
    Macro default_duty = {0};
    default_duty.loopPoint = -1;
    default_duty.values[0] = 0;
    default_duty.valueCount = 1;
    duty_macros[macro_counts[4]++] = default_duty;


    // add silent instrument
    Instrument silent_inst = {0};
    sprintf(silent_inst.name, "_Silent_%d", instrument_count);
    silent_inst.volume_id   = silent_vol_idx;
    silent_inst.arpeggio_id = default_arp_idx;
    silent_inst.pitch_id    = flat_pitch_idx;
    silent_inst.duty_id     = default_duty_idx;
    instruments[instrument_count++] = silent_inst;

	// print formated output to file
	FILE *out = fopen("tracks.s", "w");
	if (!out) {
		fprintf(stderr, "counldn't open output file");
		return 1;
	}

	// print header
	fprintf(out, ";\n; neschael\n; data/levels/****.s\n;\n; file generated by tools/formatSong.c\n; music and sfx data\n;\n\n");
	
	// print songs table
	fprintf(out, "song_list:\n");
	for (int i = 0; i < song_count; i++) {
		fprintf(out, "\t.WORD %s\n", songs[i].name);
	}
	fprintf(out, "\n");

	// sfx table
	fprintf(out, "sfx_list:\n");
	for (int i = 0; i < sfx_count; i++) {
		fprintf(out, "\t.WORD %s\n", sfx[i].name);
	}
	fprintf(out, "\n");

	// instrument table
	fprintf(out, "instrument_list:\n");
	for (int i = 0; i < instrument_count; i++) {
		fprintf(out, "\t.WORD %s\n", instruments[i].name);
	}
	fprintf(out, "; order: vol, pitch, duty, arp\n\n");	

	// instruments
	for (int i = 0; i < instrument_count; i++) {

		// fix -1 references
		if (instruments[i].volume_id == -1)   instruments[i].volume_id = silent_vol_idx;
        if (instruments[i].arpeggio_id == -1) instruments[i].arpeggio_id = default_arp_idx;
        if (instruments[i].pitch_id == -1)    instruments[i].pitch_id = flat_pitch_idx;
        if (instruments[i].duty_id == -1)     instruments[i].duty_id = default_duty_idx;

		Instrument *cur_inst = &instruments[i];
		
		fprintf(out, "%s:\n", cur_inst->name);
		// header
		int vol_start = 5; // initialize to five as the header is 5 bytes
		int pitch_start = vol_start + volume_macros[cur_inst->volume_id].valueCount + (volume_macros[cur_inst->volume_id].loopPoint == -1 ? 1 : 2);
		int duty_start = pitch_start + pitch_macros[cur_inst->pitch_id].valueCount + (pitch_macros[cur_inst->pitch_id].loopPoint == -1 ? 1 : 2);
		int arp_start = duty_start + duty_macros[cur_inst->duty_id].valueCount + (duty_macros[cur_inst->duty_id].loopPoint == -1 ? 1 : 2);
		
		fprintf(out, "\t.BYTE $05, ");
		fprintf(out, "$%02X, $%02X, $%02X, ", pitch_start, duty_start, arp_start);
		fprintf(out, "$%02X\n", arpeggio_macros[cur_inst->arpeggio_id].arpType);
		
		write_macro(out, &volume_macros[cur_inst->volume_id], 0, vol_start);
		write_macro(out, &pitch_macros[cur_inst->pitch_id], 0, pitch_start);
		write_macro(out, &duty_macros[cur_inst->duty_id], 1, duty_start);
		write_macro(out, &arpeggio_macros[cur_inst->arpeggio_id], 0, arp_start);
		fprintf(out, "\n");
	}

	return 0;
}