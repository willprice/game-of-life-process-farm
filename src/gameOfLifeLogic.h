#ifndef _GAME_OF_LIFE_LOGIC
#define _GAME_OF_LIFE_LOGIC
#include "imageProperties.h"


typedef struct {
    int x, y;
} CellPosition;


unsigned int calculateNewBoard(CellState [][IMAGE_WIDTH], CellState [][IMAGE_WIDTH], int, int);
CellState calculateNextCellState(CellState [][IMAGE_WIDTH], int, int, CellPosition);
#endif
