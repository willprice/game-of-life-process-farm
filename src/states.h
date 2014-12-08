#ifndef STATES_H_
#define STATES_H_

typedef enum {
    DIST_UNSTARTED,
    DIST_INITIALISING,
    DIST_RUNNING,
    DIST_EXPORTING,
    DIST_PAUSED,
    DIST_TERMINATING
} DistributorState;

typedef enum {
    BL_NOT_LISTENING,
    BL_LISTENING,
    BL_TERMINATING
} ButtonListenerState;

typedef enum {
    VIS_UNSTARTED,
    VIS_INITIALISING,
    VIS_RUNNING,
    VIS_EXPORTING,
    VIS_PAUSED,
    VIS_TERMINATING
} VisualiserState;

typedef enum {
    SL_RUNNING,
    SL_TERMINATING
} ShowLEDState;

typedef enum {
   DIN_UNSTARTED,
   DIN_READING,
   DIN_TERMINATING
} DataInStreamState;

typedef enum {
   DOUT_UNSTARTED,
   DOUT_WRITING,
   DOUT_TERMINATING
} DataOutStreamState;
#endif /* STATES_H_ */
