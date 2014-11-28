typedef unsigned char uchar;

#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"
#include "io.h"
#include "events.h"
#include "gameOfLife.h"

#define IMAGE_HEIGHT 16
#define IMAGE_WIDTH 16
#define NUMBER_OF_QUADRANTS 4

in port  buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;

typedef enum {
    A = 0b1110,
    B = 0b1101,
    C = 0b1011,
    D = 0b0111
} ButtonPattern;


ButtonListenerDistributorEvent handleButtonPress();

/*
 * State template
    while(state != TERMINATING) {
        switch(state) {
        case UNSTARTED:
            break;
        case RUNNING:
            break;
        case PAUSING:
            break;
        case INITIALIZING:
            break;
        case EXPORTING:
            break;
        case TERMINATING:
            break;
        }
*/

void buttonListener(chanend distributor) {
    ButtonListenerDistributorEvent event;

    GameState state = UNSTARTED;
    while(state != TERMINATING) {
#pragma fallthrough
        switch(state) {
        case UNSTARTED:
        case RUNNING:
        case PAUSING:
        case INITIALIZING:
            // Happy path
            event = handleButtonPress();
            distributor <: event;
            switch(event) {
            case STOP:
                state = TERMINATING;
                break;
            }
            break;
        case EXPORTING:
            // Tell other processes to export
            break;
        case TERMINATING:
            // Tell other processes to shut down
            break;
        }
    }
    distributor <: TERMINATED;
}

ButtonListenerDistributorEvent handleButtonPress() {
    ButtonPattern buttonState;
    buttons when pinsneq(0b1111) :> buttonState;   // check if some buttons are pressed

    switch(buttonState) {
    case A:
        return START;
    case B:
        return PLAY_PAUSE;
    case C:
        return SAVE;
    case D:
        return STOP;
    default:
        printf("Error: button press not known\n");
        return STOP;
    }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out)
{
  int res;
  uchar line[ IMAGE_WIDTH ];
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
  return;
}

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

void distributor(chanend c_in, chanend c_out, chanend buttonListener, chanend visualiser)
{
    GameState state = INITIALIZING;
    ButtonListenerDistributorEvent event;
    while (state != TERMINATING) {
#pragma fallthrough
        switch(state) {
        case UNSTARTED:
        case RUNNING:
        case PAUSING:
        case INITIALIZING:
            buttonListener :> event;
            if (event == STOP) { state = TERMINATING; }
            break;
        case EXPORTING:
            break;
        case TERMINATING:
            break;
        }
        visualiser <: state;
    }
    uchar val;
    printf( "ProcessImage:Start, size = %dx%d\n", IMAGE_HEIGHT, IMAGE_WIDTH );
    //This code is to be replaced � it is a place holder for farming out the work...
    for( int y = 0; y < IMAGE_HEIGHT; y++ )
    {
        for( int x = 0; x < IMAGE_WIDTH; x++ )
        {
            c_in :> val;
            c_out <: (uchar)(val ^ 0xFF); //Need to cast
        }
    }
    printf( "ProcessImage:Done...\n" );
    int discard;
    buttonListener :> discard;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to pgm image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in)
{
    int res;
    uchar line[ IMAGE_WIDTH ];
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
    return;
}

unsigned int calculateNumberOfAliveNeighbours(CellState cells[3][3]) {
    int numberOfAliveNeighbours = 0;
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
           if (i == 1 && j == 1) { continue; }
           if (cells[j][i] == CELL_ALIVE) { numberOfAliveNeighbours++; }
        }
    }
    return numberOfAliveNeighbours;
}

CellState calculateNextCellState(CellState cells[3][3]) {
    // Array should be [row][column] format
    //
    // We calculate the next state of the central cell of a 3x3 array of cells
    int numberOfAliveNeighbours = calculateNumberOfAliveNeighbours(cells);
    CellState previousCellState = cells[1][1];
    if (numberOfAliveNeighbours < 2) {
        return CELL_DEAD;
    } else if (previousCellState == CELL_DEAD && numberOfAliveNeighbours == 3) {
        return CELL_ALIVE;
    } else if (previousCellState == CELL_ALIVE && numberOfAliveNeighbours <= 3) {
        return CELL_ALIVE;
    } else {
        return CELL_DEAD;
    }
}

//MAIN PROCESS defining channels, orchestrating and starting the threads
int main()
{
    chan c_inIO, c_outIO; //extend your channel definitions here
    chan buttonListenerToDistributor;
    chan visualiserToDistributor;
    chan quadrants[NUMBER_OF_QUADRANTS];
    par {
        on stdcore[0]: distributor(c_inIO, c_outIO, buttonListenerToDistributor, visualiserToDistributor);
        on stdcore[0]: visualiser(visualiserToDistributor, quadrants);
        on stdcore[0]: buttonListener(buttonListenerToDistributor);

        on stdcore[1]: DataInStream("./resources/test.pgm", c_inIO);
        on stdcore[1]: DataOutStream("./output/testout.pgm", c_outIO);

        on stdcore[0]: showLED(cled0, quadrants[0]);
        on stdcore[1]: showLED(cled1, quadrants[1]);
        on stdcore[2]: showLED(cled2, quadrants[2]);
        on stdcore[3]: showLED(cled3, quadrants[3]);
    }
    return 0;
}
