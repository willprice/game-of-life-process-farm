#ifndef EVENTS_H_
#define EVENTS_H_
typedef enum {
    START,
    PLAY_PAUSE,
    SAVE,
    STOP,
    TERMINATED
} ButtonListenerDistributorEvent;

typedef enum {
    UNSTARTED,
    RUNNING,
    PAUSING,
    INITIALIZING,
    EXPORTING,
    TERMINATING
} GameState;
#endif
