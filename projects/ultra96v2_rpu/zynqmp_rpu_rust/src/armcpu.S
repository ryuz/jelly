/* ------------------------------------------------------------------------ */
/*  ARM プロセッサ固有機能                                                  */
/*                                               Copyright (C) 2021 by Ryuz */
/* ------------------------------------------------------------------------ */


                .text
                .align  2


/************************************************
  分岐予測有効化
  void 	_armcpu_enable_bpredict(void);
 ************************************************/
                .global _armcpu_enable_bpredict
_armcpu_enable_bpredict:
                mrc     p15, 0, r0, c1, c0, 1       /* Read ACTLR */
                bic     r0, r0, #0x1 << 17          /* Clear RSDIS bit 17 to enable return stack */
                bic     r0, r0, #0x1 << 16          /* Clear BP bit 15 and BP bit 16 */
                bic     r0, r0, #0x1 << 15          /* Normal operation, BP is taken from the global history table */
                mcr     p15, 0, r0, c1, c0, 1       /* Write ACTLR */
                dsb
                bx      lr

/************************************************
  分岐予測無効化
  void 	_armcpu_disable_bpredict(void);
 ************************************************/
                .global _armcpu_disable_bpredict
_armcpu_disable_bpredict:
                mrc     p15, 0, r0, c1, c0, 1       /* Read ACTLR */
                orr     r0, r0, #0x1 << 17          /* Enable RSDIS bit 17 to disable the return stack */
                orr     r0, r0, #0x1 << 16          /* Clear BP bit 15 and set BP bit 16:*/
                bic     r0, r0, #0x1 << 15          /* Branch always not taken and history table updates disabled*/
                mcr     p15, 0, r0, c1, c0, 1       /* Write ACTLR */
                dsb
                bx      lr

/************************************************
  Iキャッシュ有効化
  void 	_armcpu_enable_icache(void);
 ************************************************/
                .global _armcpu_enable_icache
_armcpu_enable_icache:
                mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
                orr     r1, r1, #0x1 << 12      /* instruction cache enable */
                mcr     p15, 0, r0, c7, c5, 0   /* Invalidate entire instruction cache */
                mcr     p15, 0, r1, c1, c0, 0   /* enabled instruction cache */
                isb
                bx      lr


/************************************************
  Iキャッシュ無効化
  void  _armcpu_disable_icache(void);
 ************************************************/
                .global _armcpu_disable_icache
_armcpu_disable_icache:
                mrc     p15, 0, R1, c1, c0, 0   /* Read System Control Register configuration data */
                bic     r1, r1, #0x1 << 12      /* instruction cache enable */
                mcr     p15, 0, r1, c1, c0, 0   /* disabled instruction cache */
                isb
                bx      lr


/************************************************
  Dキャッシュ有効化
  void 	_armcpu_enable_dcache(void);
 ************************************************/
                .global _armcpu_enable_dcache
_armcpu_enable_dcache:
                mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
                orr     r1, r1, #0x1 << 2
                dsb
                mcr     p15, 0, r0, c15, c5, 0  /* Invalidate entire data cache */
                mcr     p15, 0, r1, c1, c0, 0   /* enabled data cache */
                bx      lr


/************************************************
  Dキャッシュ無効化
  void  _armcpu_disable_dcache(void);
 ************************************************/
                .global _armcpu_disable_dcache
_armcpu_disable_dcache:
                mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
                bic     r1, r1, #0x1 << 2
                dsb
                mcr     p15, 0, r1, c1, c0, 0   /* disabled data cache */
                /* Clean entire data cache. This routine depends on the data cache size. It can be
                   omitted if it is known that the data cache has no dirty data. */
                bx      lr


/************************************************
  キャッシュ有効化
  void 	_armcpu_enable_cache(void);
 ************************************************/
                .global _armcpu_enable_cache
_armcpu_enable_cache:
                mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
                orr     r1, r1, #0x1 << 12      /* instruction cache enable */
                orr     r1, r1, #0x1 << 2       /* data cache enable */
                dsb
                mcr     p15, 0, r0, c15, c5, 0  /* Invalidate entire data cache */
                mcr     p15, 0, r0, c7, c5, 0   /* Invalidate entire instruction cache */
                mcr     p15, 0, r1, c1, c0, 0   /* enabled cache RAMs */
                isb
                bx      lr


/************************************************
  キャッシュ無効化
  void  _armcpu_disable_cache(void);
 ************************************************/
                .global _armcpu_disable_cache
_armcpu_disable_cache:
                mrc     p15, 0, r1, c1, c0, 0   /* Read System Control Register configuration data */
                bic     r1, r1, #0x1 << 12      /* instruction cache disable */
                bic     r1, r1, #0x1 << 2       /* data cache disable */
                dsb
                mcr     p15, 0, r1, c1, c0, 0   /* disabled cache RAMs */
                isb
                /* Clean entire data cache. This routine depends on the data cache size. It can be
                   omitted if it is known that the data cache has no dirty data */
                bx      lr


/************************************************
  ECC有効化 (必ずキャッシュOFF状態で呼ぶこと)
  void 	_armcpu_enable_ecc(void);
 ************************************************/
                .global _armcpu_enable_ecc
_armcpu_enable_ecc:
                mrc     p15, 0, r1, c1, c0, 1   /* Read Auxiliary Control Register */
                bic     r0, r0, #(0x1 << 5)     /* Generate abort on parity errors, with [5:3]= b000 */
                bic     r0, r0, #(0x1 << 4)
                bic     r0, r0, #(0x1 << 3)
                mcr     p15, 0, r1, c1, c0, 1   /* Write Auxiliary Control Register */
                bx      lr


/************************************************
  ECC無効化 (必ずキャッシュOFF状態で呼ぶこと)
  void 	_armcpu_disable_ecc(void);
 ************************************************/
                .global _armcpu_disable_ecc
_armcpu_disable_ecc:
                mrc     p15, 0, r1, c1, c0, 1   /* Read Auxiliary Control Register */
                orr     r0, r0, #(0x1 << 5)     /* Disable parity checking, with [5:3]= b100 */
                bic     r0, r0, #(0x1 << 4)
                bic     r0, r0, #(0x1 << 3)
                mcr     p15, 0, r1, c1, c0, 1   /* Write Auxiliary Control Register */
                bx      lr



/* Memory Barrier */
                .global _armcpu_arm_isb
                .code   16
                .thumb_func
                .type   _armcpu_arm_isb, %function
_armcpu_arm_isb:
                isb             /* そもそも分岐で呼び出してる時点で意味なしだがインライン機能のないコンパイラ用に一応作っておく */
                bx      lr


                .global _armcpu_arm_dsb
                .code   16
                .thumb_func
                .type   _armcpu_arm_dsb, %function
_armcpu_arm_dsb:
                dsb
                bx      lr


/* SCTLR CP15 Control Register */
                .global _armcpu_write_cp15_c1_c0_0
                .code   16
                .thumb_func
                .type   _armcpu_write_cp15_c1_c0_0, %function
_armcpu_write_cp15_c1_c0_0:
                dsb
                mcr     p15, 0, r0, c1, c0, 0
                isb
                bx      lr
                
                .global _armcpu_read_cp15_c1_c0_0
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c1_c0_0, %function
_armcpu_read_cp15_c1_c0_0:
                mrc     p15, 0, r0, c1, c0, 0
                bx      lr


/* ACTLR */
                .global _armcpu_read_cp15_c1_c0_1
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c1_c0_1, %function
_armcpu_write_cp15_c1_c0_1:
                mcr     p15, 0, r0, c1, c0, 1
                dsb
                bx      lr
                
                .global _armcpu_read_cp15_c1_c0_1
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c1_c0_1, %function
_armcpu_read_cp15_c1_c0_1:
                mrc     p15, 0, r0, c1, c0, 1
                bx      lr


/* MPU Type Register */
                .global _armcpu_read_cp15_c0_c0_4
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c0_c0_4, %function
_armcpu_read_cp15_c0_c0_4:
                mrc     p15, 0, r0, c0, c0, 4
                bx      lr


/* MPU Region Size and Enable Registers */
                .global _armcpu_write_cp15_c6_c1_0
                .code   16
                .thumb_func
                .type   _armcpu_write_cp15_c6_c1_0, %function
_armcpu_write_cp15_c6_c1_0:
                mcr     p15, 0, r0, c6, c1, 0
                bx      lr

                .global _armcpu_read_cp15_c6_c1_0
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c6_c1_0, %function
_armcpu_read_cp15_c6_c1_0:
                mrc     p15, 0, r0, c6, c1, 0
                bx      lr


/* MPU Region Number Register */
                .global _armcpu_write_cp15_c6_c2_0
                .code   16
                .thumb_func
                .type   _armcpu_write_cp15_c6_c2_0, %function
_armcpu_write_cp15_c6_c2_0:
                mcr     p15, 0, r0, c6, c2, 0
                bx      lr

                .global _armcpu_read_cp15_c6_c2_0
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c6_c2_0, %function
_armcpu_read_cp15_c6_c2_0:
                mrc     p15, 0, r0, c6, c2, 0
                bx      lr


/* MPU Region Access Control Register */
                .global _armcpu_write_cp15_c6_c1_4
                .code   16
                .thumb_func
                .type   _armcpu_write_cp15_c6_c1_4, %function
_armcpu_write_cp15_c6_c1_4:
                mcr     p15, 0, r0, c6, c1, 4
                bx      lr

                .global _armcpu_read_cp15_c6_c1_4
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c6_c1_4, %function
_armcpu_read_cp15_c6_c1_4:
                mrc     p15, 0, r0, c6, c2, 0
                bx      lr


/* Data MPU Region Size and Enable Register */
                .global _armcpu_write_cp15_c6_c1_2
                .code   16
                .thumb_func
                .type   _armcpu_write_cp15_c6_c1_2, %function
_armcpu_write_cp15_c6_c1_2:
                mcr     p15, 0, r0, c6, c1, 2
                bx      lr

                .global _armcpu_read_cp15_c6_c1_2
                .code   16
                .thumb_func
                .type   _armcpu_read_cp15_c6_c1_2, %function
_armcpu_read_cp15_c6_c1_2:
                mrc     p15, 0, r0, c6, c2, 0
                bx      lr


/* end of file */
