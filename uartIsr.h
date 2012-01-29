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

#ifndef UARTISR_H
#define UARTISR_H

#ifndef UART_QUEUESIZE
#define UART_QUEUESIZE 4
#endif 

#ifndef USR
#ifdef __AVR_ATmega128__
#define USR UCSR1A
#endif
#endif

#ifndef UCR
#ifdef __AVR_ATmega128__
#define UCR UCSR1B
#endif
#endif

#ifndef UDR
#ifdef __AVR_ATmega128__
#define UDR UDR1
#endif
#endif

#ifndef SIG_UART_RECV
#ifdef __AVR_ATmega128__
#define SIG_UART_RECV SIG_UART1_RECV
#endif
#endif

#ifndef SIG_UART_DATA
#ifdef __AVR_ATmega128__
#define SIG_UART_DATA SIG_UART1_DATA
#endif
#endif

#ifndef SIG_UART_TRANS
#ifdef __AVR_ATmega128__
#define SIG_UART_TRANS SIG_UART1_TRANS
#endif
#endif

#ifndef __ASM__

extern struct Semaphore uartTxSemaphore;
extern struct Semaphore uartRxSemaphore;
extern char uartStatus;
extern char uartGetStatus(void);
extern char uartStatusTestClear(char mask);
void uartIsrInitialize(void); // initialize to empty queue
extern struct Cq uartInCq, uartOutCq;
extern char uartLastByte;

#endif

#endif
