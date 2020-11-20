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
				.extern		___bss
				.extern		___bss_end
				.extern		main

				.global		_reset_handler
				.global		__main


				.text

#define Mode_USR		0x10
#define Mode_IRQ		0x12
#define Mode_FIQ		0x11
#define Mode_SVC		0x13
#define Mode_UND		0x1b
#define Mode_SYS		0x1f
#define I_Bit			0x80
#define F_Bit			0x40
#define T_Bit			0x20


#define MPU_SIZE_32		((0x04 << 1) | 1)
#define MPU_SIZE_64		((0x05 << 1) | 1)
#define MPU_SIZE_128	((0x06 << 1) | 1)
#define MPU_SIZE_256	((0x07 << 1) | 1)
#define MPU_SIZE_512	((0x08 << 1) | 1)
#define MPU_SIZE_1K		((0x09 << 1) | 1)
#define MPU_SIZE_2K		((0x0a << 1) | 1)
#define MPU_SIZE_4K		((0x0b << 1) | 1)
#define MPU_SIZE_8K		((0x0c << 1) | 1)
#define MPU_SIZE_16K	((0x0d << 1) | 1)
#define MPU_SIZE_32K	((0x0e << 1) | 1)
#define MPU_SIZE_64K	((0x0f << 1) | 1)
#define MPU_SIZE_128K	((0x10 << 1) | 1)
#define MPU_SIZE_256K	((0x11 << 1) | 1)
#define MPU_SIZE_512K	((0x12 << 1) | 1)
#define MPU_SIZE_1M		((0x13 << 1) | 1)
#define MPU_SIZE_2M		((0x14 << 1) | 1)
#define MPU_SIZE_4M		((0x15 << 1) | 1)
#define MPU_SIZE_8M		((0x16 << 1) | 1)
#define MPU_SIZE_16M	((0x17 << 1) | 1)
#define MPU_SIZE_32M	((0x18 << 1) | 1)
#define MPU_SIZE_64M	((0x19 << 1) | 1)
#define MPU_SIZE_128M	((0x1a << 1) | 1)
#define MPU_SIZE_256M	((0x1b << 1) | 1)
#define MPU_SIZE_512M	((0x1c << 1) | 1)
#define MPU_SIZE_1G		((0x1d << 1) | 1)
#define MPU_SIZE_2G		((0x1e << 1) | 1)
#define MPU_SIZE_4G		((0x1f << 1) | 1)

#define MPU_XN						(1 << 12)
#define MPU_S						(1 << 2)

#define MPU_AP_NO					(0x3 << 8)
#define MPU_AP_FULL					(0x3 << 8)

#define MPU_STRONGLY_ORDERED		((0x0 << 3) | 0x0)
#define MPU_SHAREABLE_DEVICE		((0x0 << 3) | 0x1)
#define MPU_WRITE_THROUGH			((0x0 << 3) | 0x2)
#define MPU_WRITE_BACK				((0x0 << 3) | 0x3)
#define MPU_NO_CACHEABLE			((0x1 << 3) | 0x0)
#define MPU_WRITE_BACK_ALLOC		((0x1 << 3) | 0x3)
#define MPU_NON_SHAREABLE_DEVICE	((0x2 << 3) | 0x0)

#define MPU_2_NO_CACHEABLE			((0x4 << 3) | 0x0)
#define MPU_2_WRITE_BACK_ALLOC		((0x4 << 3) | 0x1)
#define MPU_2_WRITE_THROUGH			((0x4 << 3) | 0x2)
#define MPU_2_WRITE_BACK			((0x4 << 3) | 0x3)


/************************************************
  リセットハンドラ
************************************************/
				.align		4
_reset_handler:	
				/* モード設定 */
				msr		cpsr_c, #(Mode_SYS | F_Bit | I_Bit)
				
				/* SCTLR.V クリア(例外ベクタを0番地に戻す) */
				mrc		p15, 0, r0, c1, c0, 0
				mvn		r1, #0x2000
				and		r0, r0, r1
				mcr		p15, 0, r0, c1, c0, 0
				
				/* スタック仮設定 */
				ldr		r0, =_kernel_int_isp
				ldr 	sp, [r0]
				
				
				/* DATA領域のコピー */
				ldr		r0, =___data_rom
				ldr		r1, =___data
				ldr		r2, =___data_end
data_loop:		
				cmp		r1, r2
				ldrcc	r3, [r0], #4
				strcc	r3, [r1], #4
				bcc		data_loop
				
				
				/* BSS領域の初期化 */
				ldr		r0, =___bss
				ldr		r1, =___bss_end
				mov		r2, #0
bss_loop:		
				cmp		r0, r1
				strcc	r2, [r0], #4
				bcc		bss_loop
				

				/* Iキャッシュ/Dキャッシュ無効(SCTLR) */
				mrc 	p15, 0, r1, c1, c0, 0
				ldr		r0, =0xffffeffa		/* I=1, C=1, M=1 */
				and 	r1, r1, r0
				dsb
				mcr		p15, 0, r1, c1, c0, 0
				isb

				/* 分岐予測OFF, TCM ECC */
				mrc     p15, 0, r0, c1, c0, 1       	/* Read ACTLR */
				orr     r0, r0, #(0x1 << 17)        	/* Enable RSDIS bit 17 to disable the return stack */
				orr     r0, r0, #(0x1 << 16)        	/* Clear BP bit 15 and set BP bit 16:*/
				bic     r0, r0, #(0x1 << 15)        	/* Branch always not taken and history table updates disabled*/
				orr     r0, r0, #(0x1 << 27)		/* Enable B1TCM ECC check */
				orr     r0, r0, #(0x1 << 26)		/* Enable B0TCM ECC check */
				orr     r0, r0, #(0x1 << 25)		/* Enable ATCM ECC check */
				bic		r0, r0, #(0x1 << 5)		/* Generate abort on parity errors, with [5:3]=b 000*/
				bic 	r0, r0, #(0x1 << 4)
				bic		r0, r0, #(0x1 << 3)
        		mcr     p15, 0, r0, c1, c0, 1       	/* Write ACTLR*/
				dsb				    	/* Complete all outstanding explicit memory operations*/

				/* Invalidate caches */
				mov	r0,#0				/* r0 = 0  */
				dsb
				mcr	p15, 0, r0, c7, c5, 0		/* invalidate icache */
				mcr 	p15, 0, r0, c15, c5, 0      	/* Invalidate entire data cache*/
				isb

				/* MPU設定 */
				mov     r1, #0
				mov     r0, #0
init_mpu:
				mcr     p15, 0, r0, c6, c2, 0	// RGNR
				mcr     p15, 0, r1, c6, c1, 2	// Data MPU Region Size and Enable Register
				add		r0, r0, #1
				cmp		r0, #16
				bcc		init_mpu

				// LPDDR4
				mov     r0, #0
				mcr     p15, 0, r0, c6, c2, 0	// RGNR
				ldr     r0, =0x00000000
				mcr     p15, 0, r0, c6, c1, 0	// MPU Region Base Address Register
				ldr     r0, =0x0000030b
				mcr     p15, 0, r0, c6, c1, 4	// MPU Region Access Control Register
				ldr     r0, =0x0000003d
				mcr     p15, 0, r0, c6, c1, 2	// Data MPU Region Size and Enable Register

				// LPD
				mov     r0, #1
				mcr     p15, 0, r0, c6, c2, 0	// RGNR 
				ldr     r0, =0x80000000
				mcr     p15, 0, r0, c6, c1, 0	// MPU Region Base Address Register 
	//			ldr     r0, =0x0000030b
	//			ldr     r0, =0x00000310
	//			ldr     r0, =(MPU_AP_FULL | MPU_STRONGLY_ORDERED)
	//			ldr     r0, =(MPU_AP_FULL | MPU_SHAREABLE_DEVICE)
	//			ldr     r0, =(MPU_AP_FULL | MPU_WRITE_THROUGH)
	//			ldr     r0, =(MPU_AP_FULL | MPU_WRITE_BACK)
				ldr     r0, =(MPU_AP_FULL | MPU_NO_CACHEABLE)
	//			ldr     r0, =(MPU_AP_FULL | MPU_WRITE_BACK_ALLOC)
	//			ldr     r0, =(MPU_AP_FULL | MPU_NON_SHAREABLE_DEVICE)

	//			ldr     r0, =(MPU_AP_FULL | MPU_2_NO_CACHEABLE)
	//			ldr     r0, =(MPU_AP_FULL | MPU_2_WRITE_BACK_ALLOC)
	//			ldr     r0, =(MPU_AP_FULL | MPU_2_WRITE_THROUGH)
	//			ldr     r0, =(MPU_AP_FULL | MPU_2_WRITE_BACK)

				mcr     p15, 0, r0, c6, c1, 4	// MPU Region Access Control Register 
				ldr     r0, =MPU_SIZE_256M
				mcr     p15, 0, r0, c6, c1, 2	// Data MPU Region Size and Enable Register 

				// FPD0
				mov     r0, #2
				mcr     p15, 0, r0, c6, c2, 0	// RGNR
				ldr     r0, =0xa0000000
				mcr     p15, 0, r0, c6, c1, 0	// MPU Region Base Address Register
				ldr     r0, =(MPU_AP_FULL | MPU_STRONGLY_ORDERED)
				mcr     p15, 0, r0, c6, c1, 4	// MPU Region Access Control Register
				ldr     r0, =MPU_SIZE_128M
				mcr     p15, 0, r0, c6, c1, 2	// Data MPU Region Size and Enable Register

				// FPD0
				mov     r0, #3
				mcr     p15, 0, r0, c6, c2, 0	// RGNR
				ldr     r0, =0xb0000000
				mcr     p15, 0, r0, c6, c1, 0	// MPU Region Base Address Register
				ldr     r0, =(MPU_AP_FULL | MPU_STRONGLY_ORDERED)
				mcr     p15, 0, r0, c6, c1, 4	// MPU Region Access Control Register
				ldr     r0, =MPU_SIZE_128M
				mcr     p15, 0, r0, c6, c1, 2	// Data MPU Region Size and Enable Register


				/* 分岐予測有効化(ACTLR設定) */
				mrc     p15, 0, r0, c1, c0, 1
				ldr		r1, =0xfffc7fff		/* RSDIS=0, BP=0 */
				and		r0, r0, r1
				ldr		r1, =0x00004000		/* DBWR=1 (errata 780125) */
				orr		r0, r0, r1
				mcr		p15, 0, r0, c1, c0, 1
				
				/* Iキャッシュ/Dキャッシュ有効(SCTLR) */
				mrc 	p15, 0, r1, c1, c0, 0
				ldr		r0, =0x00001005		/* I=1, C=1, M=1 */
				orr 	r1, r1, r0
//				ldr		r0, =0xffffeffa		/* I=1, C=1, M=1 */
//				and 	r1, r1, r0
				dsb
				mcr		p15, 0, r1, c1, c0, 0
				isb
				
				
				
				mrc		p15, 0, r0, c1, c0, 2	/* CP アクセスレジスタを読み込む */
				orr		r0, r0, #0x00f00000		/* NEON/VFP（コプロセッサ 10 および 11）へのフルアクセス権を有効にする */
				mcr		p15, 0, r0, c1, c0, 2	/* CP アクセスレジスタを書き込む */
				isb
				mov 	r0, #0x40000000			/* VFP および NEON ハードウェアをオンにする */
 				vmsr 	fpexc, r0				/* FPEXC の EN ビットを設定する */
				

				// test
				/*

//				ldr		r0, =0xa0000000
//				stm 	r0, {r0, r1, r2, r3, r4, r5, r6, r7}

//				ldr		r0, =0xb0000000
//				stm 	r0, {r0, r1, r2, r3, r4, r5, r6, r7}


test_start:		
				ldr		r0, =0x80000000
				ldr		r1, =0x88000000

				ldr		r4, =0xa0000000
				ldr		r5, [r4]	// 開始時刻

test_loop:
//				stm 	r0, {r0, r1, r2, r3, r4, r5, r6, r7}

				vstm	r0, {d0-d7}
//				vldm	r0, {d0-d7}
				add  	r0, #64 // #32
				cmp		r0, r1
				bcc		test_loop

				ldr		r6, [r4]	// 開始時刻
				sub		r7, r6, r5	// 経過時刻
				str		r7, [r4]

test_end:		

				b		test_end
				*/

				/* main関数の呼び出し */
				bl		main
end_loop:
				b		end_loop


__main:
				bx		lr



				.end


/* end of file */
