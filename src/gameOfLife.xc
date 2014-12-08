
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
#define LOW_DEBUG
#define NUMBER_OF_QUADRANTS 4
#define NUMBER_OF_ITERATIONS 100

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;

void terminate(chanend channel, unsigned int signal, char* name);

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
            uchar val = board[y][x] ^ 0xFF;
            output <: val;
#ifdef DEBUG
            printf("Value of output board at position (%d, %d) = %d\n", x, y, val);
#endif
        }
    }
}

DistributorState getNewStateFromButtons(DistributorState previousState, chanend buttonListener) {
    ButtonListenerDistributorEvent event;

    select {
        case buttonListener :> event:
            break;
        default:
            event = -1;
            break;
    }
    switch(event) {
    case BLD_START:
        return DIST_INITIALISING;
    case BLD_PLAY_PAUSE:
        if (previousState == DIST_PAUSED) { return DIST_RUNNING; }
        return DIST_PAUSED;
    case BLD_SAVE:
        if (previousState == DIST_RUNNING || previousState == DIST_PAUSED) { return DIST_EXPORTING; }
        return previousState;
    case BLD_STOP:
        return DIST_TERMINATING;
    default:
#ifdef DEBUG
        printf("No new state\n");
#endif
        return previousState;
    }
}

void copyBoard(CellState src[IMAGE_HEIGHT][IMAGE_WIDTH], CellState dest[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    for (int y = 0; y < IMAGE_HEIGHT; y++) {
        for (int x = 0; x < IMAGE_HEIGHT; x++) {
            dest[y][x] = src[y][x];
        }
    }
}

void distributor(chanend c_in, chanend c_out, chanend workers[4], chanend buttonListener, chanend visualiser, chanend dataIn, chanend dataOut)
{
    DistributorState state = DIST_UNSTARTED;
    DistributorState previousState = state;
    CellState board[IMAGE_HEIGHT][IMAGE_WIDTH];
    CellState nextBoard[IMAGE_HEIGHT][IMAGE_WIDTH];
    unsigned int iterationNumber = 0;

    printf("Distributor:Start\n");
    while (state != DIST_TERMINATING) {
        switch(state) {
        case DIST_UNSTARTED:
            previousState = state;
            state = getNewStateFromButtons(state, buttonListener);
            break;

        case DIST_INITIALISING:
            previousState = state;
            dataIn <: D_IN_D_READ;
            visualiser <: VD_START;
            visualiser <: IMAGE_HEIGHT * IMAGE_WIDTH;
            read_image_to_board(c_in, board);
            state = DIST_RUNNING;
            break;

        case DIST_RUNNING:
            previousState = state;
            unsigned int totalNumberOfAliveCells = calculateNewBoard(board, nextBoard, IMAGE_HEIGHT, IMAGE_WIDTH);
            copyBoard(nextBoard, board);
            visualiser <: VD_RUN;
            // No more than half the cells in the grid can be alive, so we use this as our upper limit.
            unsigned int numberOfLitLEDs = totalNumberOfAliveCells / (IMAGE_HEIGHT * IMAGE_WIDTH / 2.0);
            visualiser <: numberOfLitLEDs;
#ifdef LOW_DEBUG
            printf("iteration number: %d, %d\n", iterationNumber++);
#endif
            state = getNewStateFromButtons(state, buttonListener);
            if (iterationNumber > NUMBER_OF_ITERATIONS) { state = DIST_TERMINATING; }
            break;

        case DIST_PAUSED:
            if (previousState != DIST_PAUSED) { visualiser <: VD_PAUSE; }
            state = getNewStateFromButtons(state, buttonListener);
            unsigned int complete = (iterationNumber * 12)/ NUMBER_OF_ITERATIONS;
            visualiser <: complete;
            if (state != DIST_PAUSED) {
                switch(state) {
                case DIST_RUNNING:
                    visualiser <: VD_RUN;
                    break;
                case DIST_TERMINATING:
                    break;
                }
            }
            break;

        case DIST_EXPORTING:
            visualiser <: VD_EXPORT;
            dataOut <: D_OUT_D_EXPORT;
            DataOutDistributorEvent response;
            write_board_to_image(c_out, nextBoard);
            dataOut :> response;
            visualiser <: VD_EXPORTED;
            if (response != D_OUT_D_EXPORT) printf("Data Out did not return correct response after exporting\n");
            state = previousState;
            break;

        default:
            break;
        }
    }
    // We're now TERMINATING, synchronise with all processes
    printf("Time to terminate!\n");
    terminate(visualiser, VD_TERMINATING, "visualiser");
    terminate(dataIn, D_IN_D_TERMINATING, "dataIn");
    terminate(dataOut, D_OUT_D_TERMINATING, "dataOut");
    terminate(buttonListener, BLD_TERMINATING, "buttonListener");
}

void terminate(chanend channel, unsigned int signal, char* name) {
    int terminated = 0;
    channel <: signal;
    channel :> terminated;
    if (terminated != TERMINATED) { printf("Error: %s did not terminate.\n", name); }
#ifdef DEBUG
    else printf("%s has terminated\n", name);
#endif
}

void worker(chanend distributor) {
    while(1) { ; }
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
    chan workers[4];

    par {
        on stdcore[0]: distributor(c_inIO, c_outIO, workers, buttonListenerToDistributor, visualiserToDistributor,
                dataInToDistributor, dataOutToDistributor);
        on stdcore[0]: visualiser(visualiserToDistributor, quadrants);
        on stdcore[0]: buttonListener(buttonListenerToDistributor);

        on stdcore[1]: DataInStream("./resources/test.pgm", c_inIO, dataInToDistributor);
        on stdcore[1]: DataOutStream("./output/testout.pgm", c_outIO, dataOutToDistributor);

        on stdcore[0]: showLED(cled0, quadrants[0]);
        on stdcore[1]: showLED(cled1, quadrants[1]);
        on stdcore[2]: showLED(cled2, quadrants[2]);
        on stdcore[3]: showLED(cled3, quadrants[3]);

        on stdcore[0]: worker(workers[0]);
        on stdcore[1]: worker(workers[1]);
        on stdcore[2]: worker(workers[2]);
        on stdcore[3]: worker(workers[3]);
    }
    return 0;
}
