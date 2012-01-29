/*
 * Copyright (C) 2002-2004 Tak Auyeung 
 * (tauyeung@ieee.org or visit www.drtak.org) 
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
#include <avr/io.h>
#include "timer.h"

.lcomm counter, 2 ; internal counter

#ifndef TIMER_ISR
#define TIMER_ISR SIG_OVERFLOW2
#define TICK_FREQ 15625
#define ISR_FREQ 32000
#warn "TIMER_ISR defaulted to SIG_OVERFLOW2"
#endif

#ifdef TIMER_APP_CALL
.global TIMER_APP_CALL
#endif

;#ifndef __SFR_OFFSET
;#define __SFR_OFFSET 0
;#endif

.global rtkTickCount

; the ISR itself only takes 7 bytes including the return address
; but the application call can take a lot more

.global TIMER_ISR
TIMER_ISR:
; to use preemptive multithreading
; push two more bytes that will be changed to
; the address of yield
#ifdef TIMER_RTK_PREEMPT
    push r31
    push r30
#endif
  push r31
  push r30
  push r29
  push r28
  in   r31,_SFR_IO_ADDR(SREG)
  push r31

#ifdef TIMER_RTK_PREEMPT
  ; this is is a good time to insert code to preempt a thread
  ; change the return address of the ISR to yield
  ; we can also insert a divider logic here to preempt less frequently
  ; than the timer 
  lds r28,rtkSliceCounter
  dec r28
  in  r31,_SFR_IO_ADDR(SPH)
  in  r30,_SFR_IO_ADDR(SPL) ; Z is SP
  brne normalRet
  ; return to yield

  lds r28,rtkSliceScaler  ; reset counter to
  sts rtkSliceCounter,r28 ; prescaler value

  ldi r28,lo8(pm(rtkThreadYield))
  std Z+7,r28
  ldi r28,hi8(pm(rtkThreadYield))
  std Z+6,r28
  rjmp afterAdjustRetaddr
normalRet:
  sts rtkSliceCounter,r28
  ldi r28,lo8(pm(dummyRet))
  std Z+7,r28
  ldi r28,hi8(pm(dummyRet))
  std Z+6,r28
afterAdjustRetaddr:
#endif

.equ whatever, dummyRet

#if 0
  pop r31
  out _SFR_IO_ADDR(SREG),r31
  pop r28
  pop r29
  pop r30
  pop r31
  reti
#endif

#if TICK_FREQ != ISR_FREQ
  lds  r30,counter
  ldi  r28,lo8(TICK_FREQ)
  add  r30,r28
  lds  r31,counter+1
  ldi  r29,hi8(TICK_FREQ)
  adc  r31,r29
  ldi  r28,lo8(ISR_FREQ)
  ldi  r29,hi8(ISR_FREQ)
  cp   r30,r28
  cpc  r31,r29
  sts  counter,r30
  sts  counter+1,r31
  brcs timer_notick
  ; register a tick here
  sub  r30,r28
  sbc  r31,r29
  sts  counter,r30
  sts  counter+1,r31
#endif
  ; increment tick count
  lds  r30,rtkTickCount
  inc  r30
  sts  rtkTickCount,r30
  brne timer_end
  lds  r30,rtkTickCount+1
  inc  r30
  sts  rtkTickCount+1,r30
  brne timer_end
  lds  r30,rtkTickCount+2
  inc  r30
  sts  rtkTickCount+2,r30
  brne timer_end
  lds  r30,rtkTickCount+3
  inc  r30
  sts  rtkTickCount+3,r30
  brne timer_end
  lds  r30,rtkTickCount+4
  inc  r30
  sts  rtkTickCount+4,r30
  brne timer_end
  lds  r30,rtkTickCount+5
  inc  r30
  sts  rtkTickCount+5,r30
timer_end:
timer_notick:
  ; does anyone need to process here for each ISR invocation?
  ; PWM should be done by hardware, but stepper control can go here
  ; this is thread-free calling for efficiency, but definitely no
  ; support for scheduling or yielding
  pop r31
  out _SFR_IO_ADDR(SREG),r31
  pop r28
  pop r29
  pop r30
  pop r31
#ifdef TIMER_APP_CALL
  call TIMER_APP_CALL ; must be interrupt or signal to save/restore registers
#endif
  reti

dummyRet:
  ret
