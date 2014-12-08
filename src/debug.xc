#include <stdio.h>
#include "states.h"
#include <string.h>
#include <stdlib.h>

void printState(DistributorState state) {
    printf("State: ");
    switch(state) {
    case DIST_UNSTARTED:
        printf("UNSTARTED");
        break;
    case DIST_RUNNING:
        printf("RUNNING");
        break;
    case DIST_PAUSED:
        printf("PAUSING");
        break;
    case DIST_INITIALISING:
        printf("INITIALIZING");
        break;
    case DIST_EXPORTING:
        printf("EXPORTING");
        break;
    case DIST_TERMINATING:
        printf("TERMINATING");
        break;
    }
    printf("\n");
}

char * alias byte_to_binary(int x) {
    static char b[9];
    b[0] = '\0';

    int z;
    for (z = 128; z > 0; z >>= 1)
    {
        strcat(b, ((x & z) == z) ? "1" : "0");
    }

    return b;
}
