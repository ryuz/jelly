/* ------------------------------------------------------------------------ */
/*  ベクタテーブル                                                           */
/*                                                                          */
/*                                          Copyright (C) 1998-2021 by Ryuz */
/* ------------------------------------------------------------------------ */


                /* 外部定数宣言 */
                .global _rst_handler
                .global _und_handler
                .global _swi_handler
                .global _pre_handler
                .global _abt_handler
                .global _irq_handler
                .global _fiq_handler

                .text
                .align  2

                /* ベクタ定義 */
                ldr     pc, adr_rst_hdr
                ldr     pc, adr_und_hdr
                ldr     pc, adr_swi_hdr
                ldr     pc, adr_pre_hdr
                ldr     pc, adr_abt_hdr
                nop
                ldr     pc, adr_irq_hdr
                ldr     pc, adr_fiq_hdr

adr_rst_hdr:    
                .long   _rst_handler
adr_und_hdr:        
                .long   _und_handler
adr_swi_hdr:    
                .long   _swi_handler
adr_pre_hdr:        
                .long   _pre_handler
adr_abt_hdr:
                .long   _abt_handler
adr_irq_hdr:
                .long   _irq_handler
adr_fiq_hdr:
                .long   _fiq_handler


                .end


/* end of file */
