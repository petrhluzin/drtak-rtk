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

;#include <avr/io.h>
#include <avr/io.h>
;#include <avr/ina90.h>
#include "rtk.h"
#include "uartIsr.h"
; #ifndef __SFR_OFFSET
; #define __SFR_OFFSET 0
; #endif


; may need to implement a small circular queue so we have more time to
; process the bytes, the circular queue can be implemented as follows:
;
; one byte for head (index)
; one byte for tail (index)
; fixed start address
; same queue for reading and writing (half duplex)

.global uartTxSemaphore ; someone else declare this, but I'll use it
.global uartRxSemaphore ; someone else declare this, but I'll use it
.global uartStatus ; a single byte to store status
.global rtkSemaphoreVCont ; where to jump to in rtkSemaphoreV
.global SIG_UART_RECV
SIG_UART_RECV:
uartRecvISR:
  push r31
  in   r31,_SFR_IO_ADDR(SREG)
  ori  r31,0x80 ; pre-enable interrupt
  push r31
  push r30
  push r29
  push r28
  push r27
  push r26
  push r25
  push r24

#if 0
  lds  r31,PORTG
  ldi  r30,0x10
  eor  r31,r30
  sts  PORTG,r31
#endif

  ; receive ISR
  ; read flag, or with offline status byte
#if _SFR_IO_ADDR(USR) < 0x40
  in   r24,_SFR_IO_ADDR(USR)
#else
  lds  r24,USR
#endif
  lds  r25,uartStatus
  or   r25,r24
  sts  uartStatus,r25
  ; read byte to one-byte buffer
  push r23
  push r22
#if _SFR_IO_ADDR(UDR) < 0x40
  in   r22,_SFR_IO_ADDR(UDR)
#else
  lds  r22,UDR
#endif
  ldi  r24,lo8(uartInCq)
  ldi  r25,hi8(uartInCq)
  rcall _cqPutByte
  pop  r22
  pop  r23
  tst  r24
  breq uartRecvIsrEmpty ; q was already full, couldn't put new byte into it
;  sts  uartRxByte,r24
  ; jump to rtkSemaphoreV
  ldi  r24,lo8(uartRxSemaphore)
  ldi  r25,hi8(uartRxSemaphore)
  rjmp rtkSemaphoreVCont

uartRecvIsrEmpty:
uartIsrReturn:
  pop  r24
  pop  r25
  pop  r26
  pop  r27
  pop  r28
  pop  r29
  pop  r30
  pop  r31
  andi r31,0x7f ; defer interrupt enabling to reti
  out  SREG-__SFR_OFFSET,r31
  pop  r31
  reti

.global SIG_UART_TRANS
SIG_UART_TRANS:
  push r31
  in   r31,_SFR_IO_ADDR(SREG)
  ori  r31,0x80
  push r31
  push r30
  push r29
  push r28
  push r27
  push r26
  push r25
  push r24
;  cbi  PORTD,6
  ; read flag, or with offline status byte
#if _SFR_IO_ADDR(USR) < 0x40
  in   r24,_SFR_IO_ADDR(USR)
#else
  lds  r24,USR
#endif
  lds  r25,uartStatus
  or   r25,r24
  ori  r25,(1 << TXC)
  sts  uartStatus,r25
  ; jump to rtkSemaphoreV
  ldi  r24,lo8(uartTxSemaphore)
  ldi  r25,hi8(uartTxSemaphore)
  rjmp rtkSemaphoreVCont

.global SIG_UART_DATA
SIG_UART_DATA:
.global uartEmptyISR
uartEmptyISR:
  push r31
  in   r31,_SFR_IO_ADDR(SREG)
  ori  r31,0x80 ; by default, enable interrupt next time we come here
  push r31
  push r30
  push r29
  push r28
  push r27
  push r26
  push r25
  push r24
  ; read flag, or with offline status byte
#if _SFR_IO_ADDR(USR) < 0x40
  in   r24,_SFR_IO_ADDR(USR)
#else
  lds  r24,USR
#endif
  lds  r25,uartStatus ; read the status
  or   r25,r24 ; store it back to uartStatus
  sts  uartStatus,r25
  ldi  r24,lo8(uartOutCq)
  ldi  r25,hi8(uartOutCq)
  rcall _cqGetByte ; attempt to get a byte from outgoing queue
  tst  r25
  brne uartEmptyNoMore ; if there is no more byte to send, go to this label
#if _SFR_IO_ADDR(UDR) < 0x40
  out  _SFR_IO_ADDR(UDR),r24 ; send another byte
#else
  sts  UDR,r24
#endif
#if 0
  lds  r24,PORTG
  ldi  r25,0x10
  eor  r24,r25
  sts  PORTG,r24
#endif
uartEmptyEnd:
  ldi  r24,lo8(uartTxSemaphore)
  ldi  r25,hi8(uartTxSemaphore)
  rjmp rtkSemaphoreVCont ; then V
uartEmptyNoMore:
;  cbi  UCR,TXEN ; turn off the transmitter since I have nothing else to send
;#if UCR < 0x60
;  cbi  UCR,UDRIE ; turn off data empty interrupt, no more to send
;#else
  lds  r24,UCR
  andi r24,~(1 << UDRIE)
  sts  UCR,r24
;#endif
; just return, do not call V because we did not remove a byte from the q
  rjmp uartIsrReturn
;  pop  r24
;  pop  r25
;  pop  r26
;  pop  r27
;  pop  r28
;  pop  r29
;  pop  r30
;  pop  r31 ; 
;  out  _SFR_IO_ADDR(SREG),r31
;  pop  r31
;  ret
;  lds  r24,uartLastByte
;  tst  r24
;  breq uartEmptyEnd ; not last byte, do not enable TXCIE
;#if USR < 0x60
;  sbi  USR,TXC ; clear it now by writing a one
;  sbi  UCR,TXCIE ; enable interrupt
;#else
;  lds  r24,USR
;  ori  r24,1 << TXC
;  sts  USR,r24
;  lds  r24,UCR
;  ori  r24,1 << TXCIE
;  sts  UCR,r24
;#endif
  ; when I just put the last byte to the UART, disable the data register
  ; empty interrupt because there is no need, however, the transmit complete
  ; interrupt is enabled to know that it is time to switch off the physical
  ; tranmsitter
  ; jump to rtkSemaphoreV
  rjmp uartEmptyEnd

.global uartGetStatus
uartGetStatus:
  push r31
  in   r31,_SFR_IO_ADDR(SREG)
  cli
  push r31
  lds  r24,uartStatus
  pop  r31
  out  _SFR_IO_ADDR(SREG),r31
  pop  r31
  ret

.global uartStatusTestClear
uartStatusTestClear:
  push r31
  in   r31,_SFR_IO_ADDR(SREG)
  cli
  push r31
  push r30

  lds  r30,uartStatus
  and  r24,r30 ; reflect setting
  eor  r30,r24 ; clear this same bit
  sts  uartStatus,r30

  pop  r30
  pop  r31
  out  _SFR_IO_ADDR(SREG),r31
  pop  r31
  ret

