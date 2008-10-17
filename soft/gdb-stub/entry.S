/* ------------------------------------------------------------------------ */
/*  Hyper Operating System V4 Advance                                       */
/*    Sample program for ADuC7000 series                                    */
/*                                                                          */
/*                                  Copyright (C) 1998-2007 by Project HOS  */
/*                                  http://sourceforge.jp/projects/hos/     */
/* ------------------------------------------------------------------------ */


				.extern		__kernel_int_isp
				.extern		___data
				.extern		___data_end
				.extern		___data_rom
				.extern		___bss
				.extern		___bss_end
				.extern		_gp
				.extern		main
				.global		_entry
				.global		_exception
				.global		trap_low
				.global		main


				.text
				.set	noreorder


/************************************************
  %jp{リセットハンドラ}
************************************************/
				.ent	_entry
_entry:	
				nop
				nop
				
				la		$gp, _gp
				la		$sp, 0x01001000
	//			la		$v0, __kernel_int_isp
	//			lw		$sp, ($v0)
				
				// BSS initialize
				la	$8, ___bss
				la	$9, ___bss_end
				beq	$8, $9, bss_loop_end
				nop
				
bss_loop:		
				sw		$0, ($8)
				addi	$8, $8, 4
				bne		$8, $9, bss_loop
				nop
bss_loop_end:	
				
				
				// DATA copy
				la	$8, ___data
				la	$9, ___data_end
				la	$10, ___data_rom
				beq	$8, $9, data_loop_end
				nop
				
data_loop:		
				lw		$11, ($10)
				addi	$10, $10, 4
				sw		$11, ($8)
				addi	$8, $8, 4
				bne		$8, $9, data_loop
				nop
data_loop_end:	
				
				
				la		$8, main
				jal		$8
				nop
				j		_entry
				nop
				
				.end	_entry



				.org	0x180
				.ent	_exception
_exception:
				la	$26, trap_low
				jr	$26
				 nop

				.end	_exception



/* end of file */
