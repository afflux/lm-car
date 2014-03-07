#include<stdint.h>

char* VIDEO = (char*) 0xb8000;
uint64_t PATTERN = 0x1f441f411f451f44;
void start64(void) {
    int i;
    uint64_t * vidptr = (uint64_t*) VIDEO;
    for (i = 0; i < 80*25 / 4; ++i)
        *(vidptr++) = PATTERN;
}
