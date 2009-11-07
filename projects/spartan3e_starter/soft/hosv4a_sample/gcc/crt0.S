/* ------------------------------------------------------------------------ */
/*  Hyper Operating System V4 Advance                                       */
/*    Sample program for Jelly                                              */
/*                                                                          */
/*                                  Copyright (C) 2008 by Project HOS       */
/*                                  http://sourceforge.jp/projects/hos/     */
/* ------------------------------------------------------------------------ */


				.extern		_kernel_int_isp
				.extern		_kernel_exc_hdr
				.extern		___data
				.extern		___data_end
				.extern		___data_rom
				.extern		___bss
				.extern		___bss_end
				.extern		_gp
				.extern		main

				.global		_reset_handler
				.global		_exception_handler



				.text
				.set	noreorder


/************************************************
  %jp{リセットハンドラ}
************************************************/
				.ent	_reset_handler
_reset_handler:	
				nop
				nop
				
				la		$gp, _gp
	//			la		$sp, 0x01008000
				la		$8, _kernel_int_isp
				lw		$sp, ($8)
				
				
				// BSS initialize
				la		$8, ___bss
				la		$9, ___bss_end
				beq		$8, $9, bss_loop_end
				nop
				
bss_loop:		
				sw		$0, ($8)
				addi	$8, $8, 4
				bne		$8, $9, bss_loop
				nop
bss_loop_end:	
				
				
				// DATA copy
				la		$8, ___data
				la		$9, ___data_end
				la		$10, ___data_rom
				beq		$8, $9, data_loop_end
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
				j		_reset_handler
				nop
				
				.end	_reset_handler



/************************************************
  %jp{例外ハンドラ}
************************************************/
				.org	0x180
				.ent	_exception_handler
_exception_handler:
				la		$26, _kernel_exc_hdr
				jr		$26
				nop
				
				.end	_exception_handler



/* end of file */
