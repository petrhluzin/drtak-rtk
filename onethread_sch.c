#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/signature.h>
#include "timer.h"
#include "rtk.h"

static struct Thread mainThread; // static because it doesn't need to
                                 // leave this file

// initialize timer2 to interrupt at 5kHz, enable output compare interrupt
static void
setTimer2(void)
{
  TIMSK = (TIMSK & 0x3f) | 0x80;
  TCNT2 = 0;
  OCR2 = 49;
  TCCR2 = 0x0b;
}

// be sure to specify the following when you compile:
// -DTICKFREQ=1000  makes the tick frequencey matches milliseconds
// -DISR_FREQ=5000  makes the system know that the ISR interrupts at 5kHz
// -DTIMER_ISR=SIG_OUTPUT_COMPARE2 makes the system know that the ISR is
//                                 defined elsewhere
// this file needs to link with rtk.S and timer.S
// because rtk.S provides the RTK implementation, while
// timer.S provides the preemption ability and time tracking ability

int main(void)
{
  struct Tick wakeTime;
  // ... code before rtk is active
  rtkInitialize(&mainThread, &rtkQueues[0]);
  // ... code after rtk is active
  // let's start up the timer to provide timing
  DDRG |= 0x18;
  PORTG |= 0x18;
  setTimer2();
  _SEI(); // enable interrupts
  while (1)
  {
    PORTG ^= 0x18;
    // ... do something
    rtkTickCountGet(&wakeTime); // take a snapshot of the current time
    tickAdd4(&wakeTime, 100); // make the wake time 100 ticks from now
    // while (rtkTime < wakeTime) rtkThreadYield();
    rtkThreadSchedule(rtkCurrentThread, &wakeTime);
    // now wait 100 tick
    // when we "return" from rtkThreadSchedule, it's 100 ticks later
  }
}
