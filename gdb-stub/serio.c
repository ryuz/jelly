/* $Id: serio.c,v 1.2 2008/10/05 01:44:27 ryuji Exp $ */

#include "gdb-stub.h"

static volatile unsigned long * const serio = (unsigned long *)0x02000000;

int putDebugChar(char c)
{
	while (!(serio[1] & 2));
	serio[0] = c;
	return 1;
}

char getDebugChar(void)
{
	while (!(serio[1] & 1));
	return serio[0];
}
