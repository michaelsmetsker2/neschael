#include <stdio.h>
#include <stdint.h>

//#define MAX_SIZE (8192 + 2048)
#define MAX_SIZE 50000

uint8_t in[MAX_SIZE + 1] = {0};
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
	size_t length = fread(in, 1, MAX_SIZE + 1, stdin);
	if (length > MAX_SIZE) {
		return 1;
	}
	// find longest matches
	for (unsigned j = 1; j <= 256; j++) {
		for (size_t i = j; i < length; i++) {
			for (size_t len = cmp(in + i, in + i - j, length - i); len > 0; len--, i++) {
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
	#endif
	for (size_t i = 0; i < length; ) {
		size_t l = 0;
		for (l = 0; i < length && l < 128; i++, l++) {
			if (longest[i].length > 2) {
				break;
			}
		}
		if (l) {
			// literal: 1-128
			#if 0
			fprintf(stderr, "l %u", l);
			for (size_t j = 0; j < l; j++) {
				fprintf(stderr, " %02x", in[i - l + j]);
			}
			fputc('\n', stderr);
			#endif
			putchar(256 - l);
			fwrite(in + i - l, 1, l, stdout);
		}
		if (longest[i].length >= 2) {
			size_t l = longest[i].length;
			if (l > 128) {
				l = 128;
			}
			// match: 2-128
			#if 0
			fprintf(stderr, "r %u -%u\n", l, longest[i].index);
			#endif
			putchar(l - 1);
			putchar((i - longest[i].index) & 0xff);
			i += l;
		}
	}
	putchar(0);
	fflush(stdout);
	return ferror(stdout);
}
