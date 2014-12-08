#ifndef EVENTS_H_
#define EVENTS_H_

typedef enum {
    BLD_START,
    BLD_PLAY_PAUSE,
    BLD_SAVE,
    BLD_STOP,
    BLD_LISTEN,
    BLD_STOP_LISTENING,
    BLD_TERMINATING
} ButtonListenerDistributorEvent;

typedef enum {
   VD_START,
   VD_RUN,
   VD_EXPORT,
   VD_EXPORTED,
   VD_PAUSE,
   VD_UNPAUSE,
   VD_TERMINATING
} VisualiserDistributorEvent;

typedef enum {
   D_IN_D_READ,
   D_IN_D_TERMINATING
} DataInDistributorEvent;

typedef enum {
    D_OUT_D_EXPORT,
    D_OUT_D_TERMINATING
} DataOutDistributorEvent;

typedef enum {
   V_LED_RUN,
   V_LED_TERMINATE
} VisualiserLEDEvent;

typedef enum {
    START,
    INITIALIZED,
    EXPORT,
    EXPORTED,
    PAUSE,
    UNPAUSE,
    GET_WORK,
    GOT_WORK,
    SENT_WORK,
    FINISH_PROCESSING,
    GET_IMAGE,
    GOT_IMAGE,
    STOP_BUTTON_LISTENING,
    START_BUTTON_LISTENING,
    TERMINATE,
    TERMINATED
} Event;
#endif
