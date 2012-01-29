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

#ifndef CQ_H
#define CQ_H

#include "types.h"

struct Cq {
  void *start;
  unsigned16 capacity;
  unsigned16 head;
  unsigned16 size;
};

void cqInitialize(struct Cq *p, void *, unsigned size);
volatile int cqPutByte(struct Cq *p, char byte);
volatile int cqGetByte(struct Cq *p);

#if 0
volatile inline int cqPutInt16(struct Cq *p, int16 word)
{
  return cqPutByte(p, word & 0xff) || cqPutByte(p, word >> 8);
}

volatile inline int cqGetInt16(struct Cq *p)
{
  return cqGetByte(p) | cqGetByte(p) << 8;
}

volatile inline unsigned16 cqCapacity(struct Cq *p)
{
  return p->capacity;
}

volatile inline unsigned16 cqFree(struct Cq *p)
{
  return p->capacity - p->size;
}

volatile inline unsigned16 cqSize(struct Cq *p)
{
  return p->size;
}
#endif

#endif
