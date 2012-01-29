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
#ifndef __RTK_H
#define __RTK_H

#ifdef __CPLUSPLUS__
  extern "C" {
#endif

#define RTK_STACK_SIZE 64
#define RTK_NUMQUEUES 4

#define RTK_THREADREADY 0
#define RTK_THREADSCHEDULED 1
#define RTK_THREADWAIT 2
#define RTK_THREADKILLED 3

#ifndef __ASM__
struct Queue;

struct Tick {
  char bytes[6];
};

struct Thread {
  void *sp;
  struct Thread *next;
  struct Thread *prev;
  char flags;
  struct Tick time;
  struct Queue *queue;
};

struct Queue {
  struct Queue *next;
  struct Thread *head;
};

struct Semaphore {
  char lock;
  struct Queue queue;
};

void rtkThreadYield(void);
void rtkInitialize(struct Thread *, struct Queue *);
void rtkThreadAdd(struct Thread *, struct Queue *, void *, void (*)(void *), void *);
void rtkThreadSuicide(void);
void rtkThreadKill(struct Thread *, struct Queue *);
void rtkThreadSchedule(struct Thread *, struct Tick *);
void rtkSemaphoreInitialize(struct Semaphore *, char initial);
void rtkSemaphoreP(struct Semaphore *);
void rtkDummyP(struct Semaphore *);
int rtkSemaphoreTryP(struct Semaphore *);
void rtkSemaphoreVOpt(struct Semaphore *, char CS);
extern inline void rtkSemaphoreV(struct Semaphore *p) { rtkSemaphoreVOpt(p, 1); }
extern inline void rtkSemaphoreVNoCS(struct Semaphore *p) { rtkSemaphoreVOpt(p, 0); }
void rtkTickCountInc(void);
struct Tick *rtkTickCountGet(struct Tick *);
struct Tick *tickAdd4(struct Tick *, unsigned long);

extern struct Queue rtkQueues[RTK_NUMQUEUES];
extern struct Queue rtkScheduled;
extern struct Tick  rtkTickCount;
extern struct Thread *rtkCurrentThread;
extern unsigned char rtkSliceScaler;
extern unsigned char rtkSliceCounter;

#endif


#ifdef __CPLUSPLUS__
  }
#endif

#endif
