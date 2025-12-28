#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define WIDTH 32
#define HEIGHT 30
#define SIZE (WIDTH * HEIGHT)

// Parse a hex string like "$E4" into a uint8_t
uint8_t parse_hex(const char *s) {
    while (*s && (*s == '$' || isspace(*s))) s++; // skip $ and spaces
    return (uint8_t)strtol(s, NULL, 16);
}

// Trim leading and trailing whitespace
void trim(char *str) {
    char *end;
    while (isspace((unsigned char)*str)) str++;
    end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) *end-- = '\0';
}

int main() {
    char line[1024];
    uint8_t matrix[SIZE];
    uint8_t transposed[SIZE];
    int index = 0;

    printf("Paste 30 lines of .byte data (each with 32 $XX values):\n");

    for (int row = 0; row < HEIGHT; row++) {
        if (!fgets(line, sizeof(line), stdin)) {
            fprintf(stderr, "Error: Not enough lines of input.\n");
            return 1;
        }

        // Skip optional ".byte" and any whitespace after it
        char *ptr = strstr(line, ".byte");
        if (ptr) {
            ptr += 5;
            while (*ptr && isspace(*ptr)) ptr++;
        } else {
            ptr = line;
        }

        // Tokenize by comma and parse
        char *token = strtok(ptr, ",");
        for (int col = 0; col < WIDTH; col++) {
            if (!token) {
                fprintf(stderr, "Error: Line %d has less than 32 values.\n", row + 1);
                return 1;
            }

            trim(token);
            matrix[index++] = parse_hex(token);
            token = strtok(NULL, ",");
        }
    }

    if (index != SIZE) {
        fprintf(stderr, "Error: Got %d bytes, expected %d.\n", index, SIZE);
        return 1;
    }

    // Transpose from row-major to column-major order
    for (int col = 0; col < WIDTH; col++) {
        for (int row = 0; row < HEIGHT; row++) {
            transposed[col * HEIGHT + row] = matrix[row * WIDTH + col];
        }
    }

    // Print result
    for (int i = 0; i < SIZE; i++) {
        if (i % HEIGHT == 0) printf("\n.byte ");
        printf("$%02X", transposed[i]);
        if ((i + 1) % HEIGHT != 0) printf(", ");
    }
    printf("\n");

    return 0;
}


