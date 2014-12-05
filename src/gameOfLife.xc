
#include <platform.h>
#include <stdio.h>
#include "io.h"
#include "events.h"
#include "common_types.h"
#include "gameOfLife.h"
#include "gameOfLifeLogic.h"
#include "imageProperties.h"
#include "debug.h"

//#define DEBUG
#define NUMBER_OF_QUADRANTS 4

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;

void read_image_to_board(chanend input, CellState board[][IMAGE_WIDTH]) {
    uchar val;
    printf( "ProcessImage:Start, size = %dx%d\n", IMAGE_HEIGHT, IMAGE_WIDTH );
    for( int y = 0; y < IMAGE_HEIGHT; y++ )
    {
        for( int x = 0; x < IMAGE_WIDTH; x++ )
        {
            input :> val;
            board[y][x] = val;
#ifdef DEBUG
            printf("Value of input board at position (%d, %d) = %d\n", x, y, val);
#endif
        }
    }
    printf( "ProcessImage:Done...\n" );
}

void write_board_to_image(chanend output, CellState board[][IMAGE_WIDTH]) {
    for( int y = 0; y < IMAGE_HEIGHT; y++ )
    {
        for( int x = 0; x < IMAGE_WIDTH; x++ )
        {
            output <: (uchar)(board[y][x] ^ 0xFF) ;
#ifdef DEBUG
            printf("Value of output board at position (%d, %d) = %d\n", x, y, val);
#endif
        }
    }
}

DistributorState getNewStateFromButtons(DistributorState previousState, chanend buttonListener) {
    ButtonListenerDistributorEvent event;
    buttonListener :> event;
    switch(event) {
    case BLD_START:
        break;
    case BLD_PLAY_PAUSE:
        if (previousState == DIST_PAUSING) return DIST_RUNNING;
        else return DIST_PAUSING;
    case BLD_SAVE:
        if (previousState == DIST_RUNNING) return DIST_EXPORTING;
        else return previousState;
    case BLD_STOP:
        return DIST_TERMINATING;
    default:
        printf("getNewStateFromButtons got a weird event, wtf\n");
        return previousState;
    }
}

void distributor(chanend c_in, chanend c_out, chanend buttonListener, chanend visualiser, chanend dataIn, chanend dataOut)
{
    DistributorState state = UNSTARTED;
    CellState board[IMAGE_HEIGHT][IMAGE_WIDTH];
    CellState nextBoard[IMAGE_HEIGHT][IMAGE_WIDTH];
    while (state != TERMINATING) {
        switch(state) {
        case DIST_UNSTARTED:
            state = getNewStateFromButtons(state, buttonListener);
            visualiser <: VD_START;
            break;

        case DIST_INITIALISING:
            visualiser <: IMAGE_HEIGHT * IMAGE_HEIGHT;
            visualiser <: 0;
            read_image_to_board(c_in, board);
            state = getNewStateFromButtons(buttonListener);
            break;

        case DIST_RUNNING:
            unsigned int totalNumberOfAliveCells = calculateNewBoard(board, nextBoard, IMAGE_HEIGHT, IMAGE_WIDTH);
            visualiser <: totalNumberOfAliveCells;
            state = getNewStateFromButtons(buttonListener);
            break;

        case DIST_PAUSING:
            break;

        case DIST_EXPORTING:
            write_board_to_image(c_out, nextBoard);
            break;

        default:
            break;
        }
    }
    // We're now TERMINATING, synchronise with all processes
    visualiser <: state;
    buttonListener <: state;
    dataIn <: state;
    dataOut <: state;
    int terminated = 0;
    visualiser :> terminated;
    if (terminated != TERMINATED) { printf("Error: Visualiser did not terminate.\n"); }
    buttonListener :> terminated;
    if (terminated != TERMINATED) { printf("Error: buttonListener did not terminate.\n"); }
}



//MAIN PROCESS defining channels, orchestrating and starting the threads
int main()
{
    chan c_inIO, c_outIO; //extend your channel definitions here
    chan buttonListenerToDistributor;
    chan visualiserToDistributor;
    chan dataInToDistributor;
    chan dataOutToDistributor;
    chan quadrants[NUMBER_OF_QUADRANTS];
    par {
        on stdcore[0]: distributor(c_inIO, c_outIO, buttonListenerToDistributor, visualiserToDistributor,
                dataInToDistributor, dataOutToDistributor);
        on stdcore[0]: visualiser(visualiserToDistributor, quadrants);
        on stdcore[0]: buttonListener(buttonListenerToDistributor);

        on stdcore[1]: DataInStream("./resources/test.pgm", c_inIO, dataInToDistributor);
        on stdcore[1]: DataOutStream("./output/testout.pgm", c_outIO, dataOutToDistributor);

        on stdcore[0]: showLED(cled0, quadrants[0]);
        on stdcore[1]: showLED(cled1, quadrants[1]);
        on stdcore[2]: showLED(cled2, quadrants[2]);
        on stdcore[3]: showLED(cled3, quadrants[3]);
    }
    return 0;
}
