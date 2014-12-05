#include "gameOfLife.h"
#include "gameOfLifeLogic.h"
#include "imageProperties.h"
#include "stdio.h"
//#define DEBUG

typedef enum {
    // Corners
    CELL_UPPER_RIGHT,
    CELL_LOWER_RIGHT,
    CELL_UPPER_LEFT,
    CELL_LOWER_LEFT,
    // Edges
    CELL_TOP_EDGE,
    CELL_BOTTOM_EDGE,
    CELL_RIGHT_EDGE,
    CELL_LEFT_EDGE,
    // Normal case
    CELL_NORMAL
} CellPositionCase;

CellPositionCase calculateTopEdgeCellPositionCase(int col, int width) {
    if (col == 0) { return CELL_UPPER_LEFT; }
    if (col == width) { return CELL_UPPER_RIGHT; }
    return CELL_TOP_EDGE;
}

CellPositionCase calculateBottomEdgeCellPositionCase(int col, int width) {
    if (col == 0) { return CELL_LOWER_LEFT; }
    if (col == width) { return CELL_LOWER_RIGHT; }
    return CELL_BOTTOM_EDGE;
}

CellPositionCase calculateNotOnHorizontalEdgeCellPositionCase(int col, int width) {
    if (col == 0) { return CELL_LEFT_EDGE; }
    if (col == width) { return CELL_RIGHT_EDGE; }
    return CELL_NORMAL;
}

CellPositionCase calculateCellPositionCaseFromLoopIndices(unsigned int row, unsigned int height, unsigned int col, unsigned int width) {
    if (row == 0) { return calculateTopEdgeCellPositionCase(col, width); }
    if (row == height) { return calculateBottomEdgeCellPositionCase(col, width); }
    return calculateNotOnHorizontalEdgeCellPositionCase(col, width);
}

unsigned int _calculateNumberOfAliveNeighbours(CellState board[][IMAGE_WIDTH], unsigned int xStart, unsigned int xEnd,
        unsigned int yStart, unsigned int yEnd, CellPosition currentCell) {
    /**
     * \param cells a 2D array of CellStates that should be a maximum of 3x3,
     *        at corners 2x3, at vertical edges: 3x2, and at horizontal edges
     *        2x3
     */

    int numberOfAliveNeighbours = 0;
    for (int y = yStart; y <= yEnd; y++) {
        for (int x = xStart; x <= xEnd; x++) {
           if (x == currentCell.x && y == currentCell.y) { continue; }
           if (board[y][x] == CELL_ALIVE) { numberOfAliveNeighbours++; }
        }
    }
#ifdef DEBUG
// printf("Number of alive neighbours at (%d, %d): %d\n", currentCell.x, currentCell.y, numberOfAliveNeighbours);
#endif
    return numberOfAliveNeighbours;
}

CellState _calculateNextCellState(CellState previousState, unsigned int numberOfAliveNeighbours) {
    // Array should be [row][column] format
    //
    // We calculate the next state of the central cell of a 3x3 array of cells
    if (previousState == CELL_ALIVE) {
        if (numberOfAliveNeighbours < 2) { return CELL_DEAD; }
        if (numberOfAliveNeighbours < 4) { return CELL_ALIVE; }
    }
    else {
    // Cell must be dead
        if (numberOfAliveNeighbours == 3) { return CELL_ALIVE; }
    }
    return CELL_DEAD;
}

CellState calculateNextCellState(CellState board[][IMAGE_WIDTH], int height, int width, CellPosition currentCellPosition) {
    CellPositionCase cellPositionCase = calculateCellPositionCaseFromLoopIndices(currentCellPosition.y, height, currentCellPosition.x, width);
    int xStart, xEnd;
    int yStart, yEnd;
    switch(cellPositionCase) {
    // CORNERS
    case CELL_UPPER_RIGHT:
        xStart = width - 1;
        xEnd = width;
        yStart = 0;
        yEnd = 1;
        break;
    case CELL_UPPER_LEFT:
        xStart = 0;
        xEnd = 1;
        yStart = 0;
        yEnd = 1;
        break;
    case CELL_LOWER_RIGHT:
        xStart = width - 1;
        xEnd = width;
        yStart = height - 1;
        yEnd = height;
        break;
    case CELL_LOWER_LEFT:
        xStart = 0;
        xEnd = 1;
        yStart = height - 1;
        yEnd = height;
        break;

    // EDGES
    case CELL_TOP_EDGE:
        xStart = currentCellPosition.x - 1;
        xEnd = currentCellPosition.x + 1;
        yStart = 0;
        yEnd = 1;
        break;
    case CELL_BOTTOM_EDGE:
        xStart = currentCellPosition.x - 1;
        xEnd = currentCellPosition.x + 1;
        yStart = height - 1;
        yEnd = height;
        break;
    case CELL_RIGHT_EDGE:
        xStart = width - 1;
        xEnd = width;
        yStart = currentCellPosition.y - 1;
        yEnd = currentCellPosition.y + 1;
        break;
    case CELL_LEFT_EDGE:
        xStart = 0;
        xEnd = 1;
        yStart = currentCellPosition.y - 1;
        yEnd = currentCellPosition.y + 1;

    case CELL_NORMAL:
        xStart = currentCellPosition.x - 1;
        xEnd = currentCellPosition.x + 1;
        yStart = currentCellPosition.y - 1;
        yEnd = currentCellPosition.y + 1;
        break;
    }

    unsigned int numberOfAliveNeighbours = _calculateNumberOfAliveNeighbours(board, xStart, xEnd, yStart, yEnd, currentCellPosition);
    CellState previousState = board[currentCellPosition.y][currentCellPosition.x];
    CellState nextState = _calculateNextCellState(previousState, numberOfAliveNeighbours);
#ifdef DEBUG
    printf("cell (%d, %d) has %d neighbours, was %d, will be %d\n", currentCellPosition.x, currentCellPosition.y, numberOfAliveNeighbours, previousState, nextState);
#endif
    return nextState;
}

unsigned int calculateNewBoard(CellState board[][IMAGE_WIDTH], CellState nextBoard[][IMAGE_WIDTH], int width, int height) {
    unsigned int totalNumberOfAliveCells = 0;
    for (int y = 0; y < height; y++) {
       for (int x = 0; x < width; x++) {
           CellPosition currentCellPosition = {x, y};
           nextBoard[y][x] = calculateNextCellState(board, height, width, currentCellPosition);
           if (nextBoard[y][x] == CELL_ALIVE) {
               totalNumberOfAliveCells++;
           }
       }
   }
    return totalNumberOfAliveCells;
}
