#include <stdio.h>
#include <stdint.h>

//#define MAX_SIZE (8192 + 2048)
#define MAX_SIZE (480 + 64)

uint8_t input[MAX_SIZE] = {0};
struct {
	size_t length;
	size_t index;
} longest[MAX_SIZE];

// returns number of equal bytes
static size_t cmp(uint8_t const *const a, uint8_t const *const b, size_t len) {
	for (size_t i = 0; i < len; i++) {
		if (a[i] != b[i]) {
			return i;
		}
	}
	return len;
}

int main(void) {
	size_t length = fread(input, 1, MAX_SIZE, stdin);
	if (length != MAX_SIZE) {
		return 1;
	}
	// find longest matches
	for (unsigned j = 1; j <= 256; j++) {
		for (size_t i = j; i < length; i++) {
			for (size_t len = cmp(input + i, input + i - j, length - i); len > 0; len--, i++) {
				if (len > longest[i].length) {
					longest[i].length = len;
					longest[i].index = j;
				}
			}
		}
	}
	// spit out compressed format
	setvbuf(stdout, NULL, _IOFBF, 0);
	#if 0
	setvbuf(stderr, NULL, _IOFBF, 0);
	#else
	setvbuf(stderr, NULL, _IOLBF, 0);
	#endif
	for (size_t i = 0; i < length; ) {
		size_t l = 0;
		for (l = 0; i < length && l < 128; l++) {
			if (longest[i + l].length > 2 && i + l + 1 != 87*1 && i + l + 1 != 87*2 && i + l + 1 != 87*3 && i + l + 1 != 87*4 && i + l + 1 != 87*5) {
				break;
			}
		}
		if (l) {
			// literal: 1-128
			literal:
			if (i < 87*1 && i + l > 87*1) {
				l = 87*1 - i;
			} else if (i < 87*2 && i + l > 87*2) {
				l = 87*2 - i;
			} else if (i < 87*3 && i + l > 87*3) {
				l = 87*3 - i;
			} else if (i < 87*4 && i + l > 87*4) {
				l = 87*4 - i;
			} else if (i < 87*5 && i + l > 87*5) {
				l = 87*5 - i;
			}
			#if 0
			fprintf(stderr, ".byte <-%u", l);
			for (size_t j = 0; j < l; j++) {
				fprintf(stderr, ", $%02x", in[i + j]);
			}
			fputc('\n', stderr);
			#endif
			putchar(256 - l);
			fwrite(input + i, 1, l, stdout);
			i += l;
			if (i == 87*1 || i == 87*2 || i == 87*3 || i == 87*4 || i == 87*5) {
				putchar(0);
				//fputs(".byte 0\n", stderr);
			}
		}
		if (longest[i].length >= 2 && i + 1 != 87*1 && i + 1 != 87*2 && i + 1 != 87*3 && i + 1 != 87*4 && i + 1 != 87*5) {
			size_t l = longest[i].length;
			if (l > 128) {
				l = 128;
			}
			if (i < 87*1 && i + l > 87*1) {
				l = 87*1 - i;
			} else if (i < 87*2 && i + l > 87*2) {
				l = 87*2 - i;
			} else if (i < 87*3 && i + l > 87*3) {
				l = 87*3 - i;
			} else if (i < 87*4 && i + l > 87*4) {
				l = 87*4 - i;
			} else if (i < 87*5 && i + l > 87*5) {
				l = 87*5 - i;
			}
			// match: 2-128
			#if 0
			fprintf(stderr, ".byte %u - 1, <(%u - %u) ; $%02x", l, i, longest[i].index, in[i - longest[i].index]);
			for (size_t j = 1; j < l; j++) {
				fprintf(stderr, ", $%02x", in[i + j - longest[i].index]);
			}
			fputc('\n', stderr);
			#endif
			putchar(l - 1);
			putchar((i - longest[i].index) & 0xff);
			i += l;
			if (i == 87*1 || i == 87*2 || i == 87*3 || i == 87*4 || i == 87*5) {
				putchar(0);
				//fputs(".byte 0\n", stderr);
			}
		}
	}
	putchar(0);
	//fputs(".byte 0\n", stderr);
	fflush(stdout);
	return ferror(stdout);
}
