#include <stdio.h>
#include "states.h"

void printState(GameState state) {
    printf("State: ");
    switch(state) {
    case UNSTARTED:
        printf("UNSTARTED");
        break;
    case RUNNING:
        printf("RUNNING");
        break;
    case PAUSING:
        printf("PAUSING");
        break;
    case INITIALIZING:
        printf("INITIALIZING");
        break;
    case EXPORTING:
        printf("EXPORTING");
        break;
    case TERMINATING:
        printf("TERMINATING");
        break;
    }
    printf("\n");
}
