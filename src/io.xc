#include <platform.h>
#include "io.h"
#include "common_types.h"
#include "events.h"

#define NUMBER_OF_QUADRANTS 4

out port cledR = PORT_CLOCKLED_SELR;

int showLED(out port p, chanend visualiser) {
    unsigned int ledPattern;
    GameState state = UNSTARTED;
    while (state != TERMINATING) {
        visualiser :> ledPattern;
        p <: ledPattern;              //send pattern to LEDs
        visualiser :> state;
    }
    return 0;
}

led_pattern calculate_led_pattern(int ledNumber, int quadrantIndex) {
    bool isLedInQuadrant = (ledNumber - 1)/3 == quadrantIndex;
    if (isLedInQuadrant) {
        // LED register:
        //e.g. value 0b0cba0000
        // cba are the LEDs on your quadrants.
        return 0b00001000 << ledNumber;
    }
    return 0;
}
//PROCESS TO COhttp://serv.thinkinstacks.com:8080/ORDINATE DISPLAY of LEDs
void visualiser(chanend distributor, chanend quadrants[]) {
    cledR <: 1;
    GameState state = UNSTARTED;
    while (state != TERMINATING) {
        distributor :> state;
        for (int quadrantIndex = 0; quadrantIndex < NUMBER_OF_QUADRANTS; quadrantIndex++) {
                quadrants[quadrantIndex] <: calculate_led_pattern(1, quadrantIndex);
                quadrants[quadrantIndex] <: state;
        }
    }
}
