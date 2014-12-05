#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"
#include "io.h"
#include "common_types.h"
#include "events.h"
#include "states.h"
#include "imageProperties.h"

#define NUMBER_OF_QUADRANTS 4

out port cledR = PORT_CLOCKLED_SELR;
in port  buttons = PORT_BUTTON;

int showLED(out port p, chanend visualiser) {
    unsigned int ledPattern;
    GameState state = UNSTARTED;
    while (state != TERMINATING) {
        visualiser :> ledPattern;
        p <: ledPattern;              //send pattern to LEDs
        visualiser :> state;
    }
    visualiser <: TERMINATED;
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
//PROCESS TO COORDINATE DISPLAY of LEDs
void visualiser(chanend distributor, chanend quadrants[]) {
    cledR <: 1;
    GameState state = UNSTARTED;
    unsigned int sizeOfBoard = 0;
    unsigned int numberOfAliveCells = 0;

    distributor :> sizeOfBoard;
    while (state != TERMINATING) {
        distributor :> numberOfAliveCells;
        distributor :> state;
        for (int quadrantIndex = 0; quadrantIndex < NUMBER_OF_QUADRANTS; quadrantIndex++) {
                quadrants[quadrantIndex] <: calculate_led_pattern(0, quadrantIndex);
                quadrants[quadrantIndex] <: state;
        }
    }
    for (int quadrantIndex = 0; quadrantIndex < NUMBER_OF_QUADRANTS; quadrantIndex++) {
        int terminated = 0;
        quadrants[quadrantIndex] :> terminated;
        if (!terminated) { printf("Error: ShowLED on quadrant %d didn't terminate.\n", quadrantIndex); }
    }

    distributor <: TERMINATED;
}

/** Read Image from pgm file with path and name infname[] to channel c_out */
void DataInStream(char infname[], chanend c_out, chanend distributor)
{
    int res;
    uchar line[ IMAGE_WIDTH ];
    GameState state = UNSTARTED;

    while(state != TERMINATING) {
        switch(state) {
        case INITIALIZING:
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
            break;
        case TERMINATING:
            break;
        default:
            break;
        }
        distributor :> state;
        return;
    }
}

/** Write pixel stream from channel c_in to pgm image file */
void DataOutStream(char outfname[], chanend c_in, chanend distributor)
{
    int res;
    uchar line[ IMAGE_WIDTH ];
    GameState state = UNSTARTED;

    while(state != TERMINATING) {
        switch(state) {
        case EXPORTING:
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
            _closeoutpgm();
            printf( "DataOutStream:Done...\n" );
            break;
        case TERMINATING:
            break;
        default:
            break;
        }
        distributor :> state;
    }
    return;
}

ButtonListenerDistributorEvent handleButtonPress() {
    ButtonPattern buttonState;
    buttons when pinsneq(0b1111) :> buttonState;   // check if some buttons are pressed

    switch(buttonState) {
    case A:
        return BLD_START;
    case B:
        return BLD_PLAY_PAUSE;
    case C:
        return BLD_SAVE;
    case D:
        return BLD_STOP;
    default:
        printf("Error: button press not known\n");
        return BLD_STOP;
    }
}

void buttonListener(chanend distributor) {
    event;
    ButtonListenerState state = BL_LISTENING;
    while(state != BL_TERMINATING) {
        switch(state) {
        // Happy path
        case BL_LISTENING:
            event = handleButtonPress();
            distributor <: event;
            break;
        case BL_NOT_LISTENING:
            break;
        case BL_TERMINATING:
            break;
        }
        select {
            case distributor :> event:
                switch(event) {
                case BLD_LISTEN:
                    state = BL_LISTENING;
                    break;
                case BLD_STOP_LISTENING:
                    state = BL_NOT_LISTENING;
                    break;
                }
                break;

            default:
                break;
        }
    }
    distributor <: TERMINATED;
}
