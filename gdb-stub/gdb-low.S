/*
 * gdb-low.S contains the low-level trap handler for the GDB stub.
 *
 * Copyright (C) 1995 Andreas Busse
 */

#include "asm.h"
#include "regdef.h"
#include "gdb-stub.h"

/*
 * [jsun] We reserves about 2x GDB_FR_SIZE in stack.  The lower (addressed)
 * part is used to store registers and passed to exception handler.
 * The upper part is reserved for "call func" feature where gdb client
 * saves some of the regs, setups call frame and passes args.
 *
 * A trace shows about 200 bytes are used to store about half of all regs.
 * The rest should be big enough for frame setup and passing args.
 */

/*
 * The low level trap handler
 */
		.align 	5
		NESTED(trap_low, GDB_FR_SIZE, sp)
 		.set	noat
		.set 	noreorder

		move	k1, sp
		move	k0, sp
		subu	sp, k1, GDB_FR_SIZE*2	# see comment above
		LONG_S	k0, GDB_FR_REG29(sp)
		LONG_S	$2, GDB_FR_REG2(sp)

/*
 * First save the CP0 and special registers
 */
		move	v0, zero
		LONG_S  v0, GDB_FR_STATUS(sp)
		move	v0, zero
		LONG_S  v0, GDB_FR_CAUSE(sp)
		move	v0, ra
		LONG_S  v0, GDB_FR_EPC(sp)
		move	v0, zero
		LONG_S  v0, GDB_FR_BADVADDR(sp)
		mfhi	v0
		LONG_S	v0, GDB_FR_HI(sp)
		mflo	v0
		LONG_S	v0, GDB_FR_LO(sp)

/*
 * Now the integer registers
 */

		LONG_S	zero, GDB_FR_REG0(sp)		/* I know... */
		LONG_S	$1, GDB_FR_REG1(sp)
		/* v0 already saved */
		LONG_S	$3, GDB_FR_REG3(sp)
		LONG_S	$4, GDB_FR_REG4(sp)
		LONG_S	$5, GDB_FR_REG5(sp)
		LONG_S	$6, GDB_FR_REG6(sp)
		LONG_S	$7, GDB_FR_REG7(sp)
		LONG_S	$8, GDB_FR_REG8(sp)
		LONG_S	$9, GDB_FR_REG9(sp)
		LONG_S	$10, GDB_FR_REG10(sp)
		LONG_S	$11, GDB_FR_REG11(sp)
		LONG_S	$12, GDB_FR_REG12(sp)
		LONG_S	$13, GDB_FR_REG13(sp)
		LONG_S	$14, GDB_FR_REG14(sp)
		LONG_S	$15, GDB_FR_REG15(sp)
		LONG_S	$16, GDB_FR_REG16(sp)
		LONG_S	$17, GDB_FR_REG17(sp)
		LONG_S	$18, GDB_FR_REG18(sp)
		LONG_S	$19, GDB_FR_REG19(sp)
		LONG_S	$20, GDB_FR_REG20(sp)
		LONG_S	$21, GDB_FR_REG21(sp)
		LONG_S	$22, GDB_FR_REG22(sp)
		LONG_S	$23, GDB_FR_REG23(sp)
		LONG_S	$24, GDB_FR_REG24(sp)
		LONG_S	$25, GDB_FR_REG25(sp)
		LONG_S	$26, GDB_FR_REG26(sp)
		LONG_S	$27, GDB_FR_REG27(sp)
		LONG_S	$28, GDB_FR_REG28(sp)
		/* sp already saved */
		LONG_S	$30, GDB_FR_REG30(sp)
		LONG_S	$31, GDB_FR_REG31(sp)

/*
 * Current stack frame ptr
 */

		LONG_S	sp, GDB_FR_FRP(sp)

		.set	at

/*
 * Continue with the higher level handler
 */

		move	a0,sp

		jal	handle_exception
		 nop

/*
 * Restore all writable registers, in reverse order
 */

		.set	noat

		LONG_L	v0, GDB_FR_HI(sp)
		LONG_L	v1, GDB_FR_LO(sp)
		mthi	v0
		mtlo	v1
		LONG_L	$31, GDB_FR_REG31(sp)
		LONG_L	$30, GDB_FR_REG30(sp)
		LONG_L	$28, GDB_FR_REG28(sp)
		LONG_L	$27, GDB_FR_REG27(sp)
		LONG_L	$26, GDB_FR_REG26(sp)
		LONG_L	$25, GDB_FR_REG25(sp)
		LONG_L	$24, GDB_FR_REG24(sp)
		LONG_L	$23, GDB_FR_REG23(sp)
		LONG_L	$22, GDB_FR_REG22(sp)
		LONG_L	$21, GDB_FR_REG21(sp)
		LONG_L	$20, GDB_FR_REG20(sp)
		LONG_L	$19, GDB_FR_REG19(sp)
		LONG_L	$18, GDB_FR_REG18(sp)
		LONG_L	$17, GDB_FR_REG17(sp)
		LONG_L	$16, GDB_FR_REG16(sp)
		LONG_L	$15, GDB_FR_REG15(sp)
		LONG_L	$14, GDB_FR_REG14(sp)
		LONG_L	$13, GDB_FR_REG13(sp)
		LONG_L	$12, GDB_FR_REG12(sp)
		LONG_L	$11, GDB_FR_REG11(sp)
		LONG_L	$10, GDB_FR_REG10(sp)
		LONG_L	$9, GDB_FR_REG9(sp)
		LONG_L	$8, GDB_FR_REG8(sp)
		LONG_L	$7, GDB_FR_REG7(sp)
		LONG_L	$6, GDB_FR_REG6(sp)
		LONG_L	$5, GDB_FR_REG5(sp)
		LONG_L	$4, GDB_FR_REG4(sp)
		LONG_L	$3, GDB_FR_REG3(sp)
		LONG_L	$2, GDB_FR_REG2(sp)
		LONG_L	$1, GDB_FR_REG1(sp)
		LONG_L	k0, GDB_FR_EPC(sp)
		LONG_L	$29, GDB_FR_REG29(sp)		/* Deallocate stack */
		jr	k0
		 nop
		.set	at
		.set	reorder
		END(trap_low)
