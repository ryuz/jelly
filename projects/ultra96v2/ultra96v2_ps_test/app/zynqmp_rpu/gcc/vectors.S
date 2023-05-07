/* ------------------------------------------------------------------------ */
/*  Hyper Operating System V4  サンプルプログラム                           */
/*    ベクタテーブル                                                        */
/*                                                                          */
/*                                  Copyright (C) 1998-2007 by Project HOS  */
/*                                  http://sourceforge.jp/projects/hos/     */
/* ------------------------------------------------------------------------ */


		/* --- 外部定数宣言 */
				.global	_reset_handler
				.global	_kernel_und_hdr
				.global	_kernel_swi_hdr
				.global	_kernel_pre_hdr
				.global	_kernel_abt_hdr
				.global	_kernel_irq_hdr
				.global	_kernel_fiq_hdr


				.text
				.align	2

/* --------------------------------------- */
/*            ベクタ定義                   */
/* --------------------------------------- */
				ldr		pc, adr_rst_hdr
				ldr		pc, adr_und_hdr
				ldr		pc, adr_swi_hdr
				ldr		pc, adr_pre_hdr
				ldr		pc, adr_abt_hdr
				nop
				ldr		pc, adr_irq_hdr
				ldr		pc, adr_fiq_hdr


adr_rst_hdr:	
				.long	_reset_handler
adr_und_hdr:		
				.long	_kernel_und_hdr
adr_swi_hdr:	
				.long	_kernel_swi_hdr
adr_pre_hdr:		
				.long	_kernel_pre_hdr
adr_abt_hdr:
				.long	_kernel_abt_hdr
adr_irq_hdr:
				.long	_kernel_irq_hdr
adr_fiq_hdr:
				.long	_kernel_fiq_hdr


				.end


/* end of file */
