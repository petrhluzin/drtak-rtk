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
#ifndef __SFR_OFFSET
#define __SFR_OFFSET 0
#endif

.equ cq_start, 0
.equ cq_capacity, cq_start+2
.equ cq_head, cq_capacity+2
.equ cq_size, cq_head+2

.global cqInitialize
cqInitialize:
  ; r25:24 - address of the cq
  ; r23:22 - start address
  ; r21:20 - size of buffer

  push r31
  push r30
  push r23
  push r22

  mov  r30,r24
  mov  r31,r25
  ; Z points to cq
  std  Z+cq_start,r22
  std  Z+cq_start+1,r23
  std  Z+cq_capacity,r20
  std  Z+cq_capacity+1,r21
  ldi  r20,0
  std  Z+cq_head,r20
  std  Z+cq_head+1,r20
  std  Z+cq_size,r20
  std  Z+cq_size+1,r20
  pop  r22
  pop  r23
  pop  r30
  pop  r31
  ret

.global cqPutByte
cqPutByte:
  push r31
  push r30
  push r27
  push r26
  push r23
  in   r23,SREG-__SFR_OFFSET
  push r23
  cli

  rcall _cqPutByte

  pop  r23
  out  SREG-__SFR_OFFSET,r23
  pop  r23
  pop  r26
  pop  r27
  pop  r30
  pop  r31
  ret

.global _cqPutByte
_cqPutByte:
  ; modifies r23 and r22, X and Z
  ; r25:24: address of cq
  ; r22: byte to put
  mov  r30,r24
  mov  r31,r25
  ; Z points to the cq
  ldd  r26,Z+cq_size
  ldd  r27,Z+cq_size+1
  ldd  r24,Z+cq_capacity
  ldd  r25,Z+cq_capacity+1
  cp   r26,r24
  cpc  r27,r25
  brcc cqPutByte_noroom ; if size >= capacity, branch
  ; else (size < capacity)
  adiw r26,1 ; add one to size
  std  Z+cq_size,r26
  std  Z+cq_size+1,r27 ; store new size
  sbiw r26,1 ; restore size so we can compute where to store the byte
  ldd  r23,Z+cq_head
  add  r26,r23
  ldd  r23,Z+cq_head+1
  adc  r27,r23 ; X is the index to the byte (tail index)
  cpc  r26,r24
  cpc  r27,r25 ; compare to capacity
  brcs cqPutByte_nowrap ; if index < capacity, no wrap
  ; else (index >= capacity)
  ; wrap around
  sub  r26,r24
  sbc  r27,r25
  rjmp cqPutByte_done
cqPutByte_nowrap:
cqPutByte_done:
  ldd  r24,Z+cq_start
  add  r26,r24
  ldd  r24,Z+cq_start+1
  adc  r27,r24 ; compute address to put byte
  st   X,r22 ; store the byte
  clr  r25
  ldi  r24,1
  ret
cqPutByte_noroom:
  clr  r25
  clr  r24
  ret

.global cqGetByte
cqGetByte:
  push r31
  push r30
  push r27
  push r26
  in   r26,SREG-__SFR_OFFSET
  push r26
  cli

  rcall _cqGetByte

  pop  r26
  out  SREG-__SFR_OFFSET,r26
  pop  r26
  pop  r27
  pop  r30
  pop  r31
  ret

.global _cqGetByte
_cqGetByte:
  ; r25:24 addreess of cq

  mov  r30,r24
  mov  r31,r25
  ; Z points to cq
  ldd  r26,Z+cq_size
  ldd  r27,Z+cq_size+1
  cpi  r26,0
  brne cqGetByte_nonempty
  cpi  r27,0
  brne cqGetByte_nonempty
  ; must be empty!
  ldi  r25,0xff
  ldi  r24,0xff
  ret

cqGetByte_nonempty:
  ; X is size
  sbiw r26,1
  std  Z+cq_size, r26
  std  Z+cq_size+1,r27 ; store new size
  ldd  r26,Z+cq_head
  ldd  r27,Z+cq_head+1
  ldd  r24,Z+cq_capacity
  adiw  r26,1 ; pre add 1, will adjust later
  cp   r26,r24
  ldd  r24,Z+cq_capacity+1
  cpc  r27,r24
  brcc cqGetByte_wrap
  ; no need to wrap
  std  Z+cq_head,r26
  std  Z+cq_head+1,r27
  rjmp cqGetByte_get
cqGetByte_wrap:
  ldi  r24,0
  std  Z+cq_head,r24
  std  Z+cq_head+1,r24 ; new head is zero
cqGetByte_get:
  ; X is the head index
  sbiw r26,1 ; restore so we can retrieve
  ldd  r24,Z+cq_start
  add  r26,r24
  ldd  r24,Z+cq_start+1
  adc  r27,r24
  ld   r24,X
  ldi  r25,0
  ret

.global cqEmpty
cqEmpty:
  push r31
  push r30
  in   r31,SREG-__SFR_OFFSET
  push r31
  cli
  mov  r30,r24
  mov  r31,r25
  ; Z points ot cq
  ldd  r24,Z+cq_size
  ldd  r25,Z+cq_size+1
  or   r24,r25
  breq cqEmptyTrue
  clr  r24
  clr  r25
  rjmp cqEmpty_end
cqEmptyTrue:
  ldi  r24,1
  clr  r25
cqEmpty_end:
  pop  r31
  out  SREG-__SFR_OFFSET,r31
  pop  r30
  pop  r31
  ret
