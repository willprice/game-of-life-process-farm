#ifndef STATES_H_
#define STATES_H_

typedef enum {
    DIST_UNSTARTED,
    DIST_INITIALISING,
    DIST_RUNNING,
    DIST_EXPORTING,
    DIST_PAUSING,
    DIST_TERMINATING
} DistributorState;

typedef enum {
    BL_NOT_LISTENING,
    BL_LISTENING,
    BL_TERMINATING
} ButtonListenerState;

#endif /* STATES_H_ */
