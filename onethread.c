#include "rtk.h"

struct Thread mainThread;

int main(void)
{
  // ... code before rtk is active
  rtkInitialize(&mainThread, &rtkQueues[0]);
  // ... code after rtk is active
  // not exciting because with one thread, there isn't much you need to use
  // from the RTK
  while (1)
  {
  }
}
