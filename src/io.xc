#include <platform.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "debug.h"
#include "pgmIO.h"
#include "io.h"
#include "common_types.h"
#include "events.h"
#include "states.h"
#include "imageProperties.h"

#define NUMBER_OF_QUADRANTS 4

out port cledR = PORT_CLOCKLED_SELR;
in port  buttons = PORT_BUTTON;

void waitMoment() {
    timer tmr;
    uint waitTime;
    tmr :> waitTime;
    waitTime += 50000000;
    tmr when timerafter(waitTime) :> void;
}

int showLED(out port p, chanend visualiser) {
    unsigned int ledPattern = 0;
    ShowLEDState state = SL_RUNNING;
    VisualiserLEDEvent event;

    while (state != SL_TERMINATING) {
        visualiser :> event;
        switch(event) {
        case V_LED_TERMINATE:
            state = SL_TERMINATING;
            break;
        default:
            visualiser :> ledPattern;
            p <: ledPattern;              //send pattern to LEDs
            break;
        }
    }
    visualiser <: TERMINATED;
    return 0;
}

void calculate_led_patterns(led_pattern patterns[4], int numberOfLeds) {
    for (int quadrantIndex = 0; quadrantIndex < 4; quadrantIndex++) {
        if (numberOfLeds >= 3) {
            // turn all LEDs on in quadrant
            patterns[quadrantIndex] = 0b01110000;
            numberOfLeds -= 3;
        } else if (numberOfLeds > 0) {
            patterns[quadrantIndex] = calculate_led_pattern(numberOfLeds);
            numberOfLeds = 0;
        } else {
            patterns[quadrantIndex] = 0;
        }
    }
}
led_pattern calculate_led_pattern(int numberOfLeds) {
    // LED register:
    //e.g. value 0b0cba0000
    // cba are the LEDs on your quadrants.
    led_pattern pattern = 0b00000000;

    for (int i = 0; i < numberOfLeds; i++) {
        pattern |= (0b00010000 << i);
    }
#ifdef DEBUG
    printf("Pattern: %s\n", byte_to_binary(pattern));
#endif
    return pattern;
}

void useRedLEDs() {
    cledR <: 1;
}

VisualiserState visualiserGetStateFromDistributor(chanend distributor, VisualiserState previousState) {
    VisualiserDistributorEvent event;
    distributor :> event;
    switch (event) {
    case VD_START:
        return VIS_INITIALISING;
    case VD_EXPORT:
        return VIS_EXPORTING;
    case VD_PAUSE:
        if (previousState != VD_PAUSE) { return VIS_PAUSED; }
        return previousState;
    case VD_TERMINATING:
        return VIS_TERMINATING;
    case VD_RUN:
        return VIS_RUNNING;
    case VD_EXPORTED:
        return previousState;
    }
}
/** PROCESS TO COORDINATE DISPLAY of LEDs */
void visualiser(chanend distributor, chanend quadrants[]) {
    VisualiserState state = VIS_UNSTARTED;
    VisualiserState previousState = state;
    unsigned int sizeOfBoard = 0;
    unsigned int numberOfAliveCells = 0;

    useRedLEDs();

    while (state != VIS_TERMINATING) {
        previousState = state;
        state = visualiserGetStateFromDistributor(distributor, previousState);
        switch(state) {
        case VIS_UNSTARTED:
            break;

        case VIS_INITIALISING:
            distributor :> sizeOfBoard;
            state = VIS_RUNNING;
            break;

        case VIS_RUNNING:
            led_pattern patterns[4];
            distributor :> numberOfAliveCells;
#ifdef DEBUG
            printf("numberOfAliveCells: %d\n", numberOfAliveCells);
#endif
            calculate_led_patterns(patterns, numberOfAliveCells);
            for (int quadrantIndex = 0; quadrantIndex < NUMBER_OF_QUADRANTS; quadrantIndex++) {
                quadrants[quadrantIndex] <: V_LED_RUN;
                quadrants[quadrantIndex] <: patterns[quadrantIndex];
            }
            break;

        case VIS_EXPORTING:
            break;

        case VIS_PAUSED:
            break;
        }
    }
    for (int quadrantIndex = 0; quadrantIndex < NUMBER_OF_QUADRANTS; quadrantIndex++) {
        int terminated = 0;
        quadrants[quadrantIndex] <: V_LED_TERMINATE;
        quadrants[quadrantIndex] :> terminated;
        if (terminated != TERMINATED) { printf("Error: ShowLED on quadrant %d didn't terminate.\n", quadrantIndex); }
    }
    distributor <: TERMINATED;
}

/** Read Image from pgm file with path and name infname[] to channel c_out */
void DataInStream(char infname[], chanend c_out, chanend distributor)
{
    int res;
    uchar line[ IMAGE_WIDTH ];
    DataInStreamState state = DIN_UNSTARTED;
    DataInDistributorEvent event;


    while(state != DIN_TERMINATING) {
        switch(state) {
        case DIN_UNSTARTED:
            distributor :> event;
            switch (event) {
            case D_IN_D_READ:
                state = DIN_READING;
                break;
            case D_IN_D_TERMINATING:
                state = DIN_TERMINATING;
                break;
            default:
                break;
            }
            break;
        case DIN_READING:
            printf( "DataInStream:Start...\n" );
            res = _openinpgm( infname, IMAGE_WIDTH, IMAGE_HEIGHT );
            if( res )
            {
                printf( "DataInStream:Error openening %s\n.", infname );
                return;
            }
            for( int y = 0; y < IMAGE_HEIGHT; y++ )
            {
                _readinline( line, IMAGE_WIDTH );
                for( int x = 0; x < IMAGE_WIDTH; x++ )
                {
                    c_out <: line[x];
                    //printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
                }
                //printf( "\n" ); //uncomment to show image values
            }
            _closeinpgm();
            printf( "DataInStream:Done...\n" );
            state = DIN_UNSTARTED;
            break;
        case DIN_TERMINATING:
            break;
        default:
            break;
        }
    }
    distributor <: TERMINATED;
}

/** Write pixel stream from channel c_in to pgm image file */
void DataOutStream(char outfname[], chanend c_in, chanend distributor)
{
    int res;
    uchar line[ IMAGE_WIDTH ];
    DataOutStreamState state = DOUT_UNSTARTED;
    DataOutDistributorEvent event;

    while(state != DOUT_TERMINATING) {
        select {
            case distributor :> event:
                switch(event) {
                case D_OUT_D_EXPORT:
                    state = DOUT_WRITING;
                    break;
                case D_OUT_D_TERMINATING:
                    state = DOUT_TERMINATING;
                    break;
                }
                break;
            default:
                break;
        }

        switch(state) {
        case DOUT_UNSTARTED:
            break;
        case DOUT_WRITING:
            printf( "DataOutStream:Start...\n" );
            res = _openoutpgm( outfname, IMAGE_WIDTH, IMAGE_HEIGHT );
            if( res )
            {
                printf( "DataOutStream:Error opening %s\n.", outfname );
                return;
            }
            for( int y = 0; y < IMAGE_HEIGHT; y++ )
            {
                for( int x = 0; x < IMAGE_WIDTH; x++ )
                {
                    c_in :> line[x];
                }
                _writeoutline( line, IMAGE_WIDTH );
            }
            distributor <: D_OUT_D_EXPORT;
            _closeoutpgm();
            printf( "DataOutStream:Done...\n" );
            state = DOUT_UNSTARTED;
            break;
        case DOUT_TERMINATING:
            break;
        default:
            break;
        }
    }
    distributor <: TERMINATED;
}

void handleButtonPress(chanend distributor) {
    select {
    }
}


void buttonListener(chanend distributor) {
    ButtonListenerDistributorEvent event;
    ButtonPattern buttonState;
    ButtonListenerState state = BL_LISTENING;
    while(state != BL_TERMINATING) {
        select {
        // Buttons are active low
        case buttons when pinsneq(0b1111) :> buttonState:
            if (state == BL_LISTENING) {
                switch(buttonState) {
                case A:
                    distributor <: BLD_START;
                    break;
                case B:
                    distributor <: BLD_PLAY_PAUSE;
                    break;
                case C:
                    distributor <: BLD_SAVE;
                    break;
                case D:
                    distributor <: BLD_STOP;
                    break;
                }
            }
        waitMoment();
        break;

        case distributor :> event:
            switch(event) {
            case BLD_LISTEN:
                state = BL_LISTENING;
                break;
            case BLD_STOP_LISTENING:
                state = BL_NOT_LISTENING;
                break;
            case BLD_TERMINATING:
                state = BL_TERMINATING;
                break;
            }
        break;
        }
    }
    distributor <: TERMINATED;
}
