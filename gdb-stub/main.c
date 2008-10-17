/* $Id: main.c,v 1.1 2008/10/05 00:48:48 ryuji Exp $ */

#include "gdb-stub.h"
#include "string.h"

int main(void)
{
	struct gdb_regs regs;
	memset(&regs, 0, sizeof(regs));
	set_debug_traps();
	breakpoint();
	return 0;
}
