/*
 * Copyright (C) 2002 Tak Auyeung (tauyeung@ieee.org or visit www.mobots.com) 
 *
 * This file is part of EbO (Embedded-but-Open).
 *
 * EbO is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * EbO is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *
 * */

#include <compat/ina90.h>
#include "rtk.h"
#include "cq.h"
#include "uartIsr.h"

struct Semaphore uartTxSemaphore;
struct Semaphore uartRxSemaphore;
struct Cq uartInCq;
struct Cq uartOutCq;
char uartStatus = 0;
char uartLastByte;
char uartInBuf[UART_QUEUESIZE];
char uartOutBuf[UART_QUEUESIZE];

void 
uartIsrInitialize(void)
{
  cqInitialize(&uartInCq, uartInBuf, sizeof(uartInBuf));
  cqInitialize(&uartOutCq, uartOutBuf, sizeof(uartOutBuf));
  rtkSemaphoreInitialize(&uartTxSemaphore,UART_QUEUESIZE); // starts with empty buffer
  rtkSemaphoreInitialize(&uartRxSemaphore,0);
  uartStatus = 0;
  uartLastByte = 0;
}
