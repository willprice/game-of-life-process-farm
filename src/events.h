#ifndef EVENTS_H_
#define EVENTS_H_
typedef enum {
    BLD_START,
    BLD_PLAY_PAUSE,
    BLD_SAVE,
    BLD_STOP,
    BLD_LISTEN,
    BLD_STOP_LISTENING
} ButtonListenerDistributorEvent;

typedef enum {
   VD_START
} VisualiserDistributorEvent;

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
