#include <avr/io.h>
#include <avr/ina90.h>
#include <avr/signal.h>
#include "timer.h"
#include "rtk.h"

static struct Thread mainThread, subThread; // static because it doesn't need to
                                 // leave this file

static char newStack[128];

// initialize timer2 to interrupt at 5kHz, enable output compare interrupt
static void
setTimer2(void)
{
  output(TIMSK, (input(TIMSK) & 0x3f) | 0x80);
  output(TCNT2,0);
  output(OCR2, 49);
  output(TCCR2,0x0b);
}

// be sure to specify the following when you compile:
// -DTICKFREQ=1000  makes the tick frequencey matches milliseconds
// -DISR_FREQ=5000  makes the system know that the ISR interrupts at 5kHz
// -DTIMER_ISR=SIG_OUTPUT_COMPARE2 makes the system know that the ISR is
//                                 defined elsewhere
// this file needs to link with rtk.S and timer.S
// because rtk.S provides the RTK implementation, while
// timer.S provides the preemption ability and time tracking ability

void
thread2(void *p)
{
  while (1)
  {
    PORTG ^= 0x08;
    // rtkThreadYield();
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
  // let's start up the timer to provide timing
  setTimer2();
  _SEI();
  while (1)
  {
//    output(PORTG, input(PORTG) ^ 0x10);
    PORTG ^= 0x10;
    // rtkThreadYield();
  }
}
