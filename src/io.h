typedef unsigned int led_pattern;

typedef enum {
    A = 0b1110,
    B = 0b1101,
    C = 0b1011,
    D = 0b0111
} ButtonPattern;

led_pattern calculate_led_pattern(int ledNumber);
void visualiser(chanend, chanend []);
int showLED(out port p, chanend visualiser);

void DataOutStream(char outfname[], chanend c_in, chanend distributor);
void DataInStream(char infname[], chanend c_out, chanend distributor);

void buttonListener(chanend distributor);

