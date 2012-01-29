#include <avr/io.h>
#include <avr/ina90.h>
#include <avr/signal.h>
#include "timer.h"
#include "rtk.h"

static struct Thread mainThread, subThread; // static because it doesn't need to
                                 // leave this file

static char newStack[128]; // allocation of 128 bytes for the second thread

void
thread2(void *p)
{
  while (1)
  {
    PORTG ^= 0x08;
    rtkThreadYield();
  }
}

int main(void)
{
  // ... code before rtk is active
  output(DDRG, input(DDRG) | 0x18); // set pins to LEDs to output
  output(PORTG, (input(PORTG) | 0x18)); // turn off both LEDs
  output(MCUCR, (input(MCUCR) & ~0x10) | 0x20); // enable idle mode

  // set up time slice parameters
  rtkSliceScaler = 100; // preemption time slice is 100 ISR invocations
  rtkSliceCounter = rtkSliceScaler; // reset it now

  rtkInitialize(&mainThread, &rtkQueues[0]);
  rtkThreadAdd(&subThread, &(rtkQueues[0]), newStack+sizeof(newStack),
               thread2, 0);
  // ... code after rtk is active
  while (1)
  {
//    output(PORTG, input(PORTG) ^ 0x10);
    PORTG ^= 0x10;
    rtkThreadYield();
  }
}
