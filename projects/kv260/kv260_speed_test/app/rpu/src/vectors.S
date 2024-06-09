// --------------------------------------------------------------------------
//  ベクタテーブル
//
//                                          Copyright (C) 1998-2021 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


                /* 外部定数宣言 */
                .global _vector_table
                .global _rst_handler
                .global _und_handler
                .global _svc_handler
                .global _pre_handler
                .global _abt_handler
                .global _irq_handler
                .global _fiq_handler
                .extern jelly_irq_handler
                .extern jelly_svc_handler

          /*    .text  */
                .section  .vector
                .align  2

                /* ベクタ定義 */
_vector_table:
                ldr     pc, adr_rst_hdr
                ldr     pc, adr_und_hdr
                ldr     pc, adr_svc_hdr
                ldr     pc, adr_pre_hdr
                ldr     pc, adr_abt_hdr
                nop
                ldr     pc, adr_irq_hdr
                ldr     pc, adr_fiq_hdr

adr_rst_hdr:    
                .long   _rst_handler
adr_und_hdr:        
                .long   _und_handler
adr_svc_hdr:    
                .long   jelly_svc_handler
adr_pre_hdr:        
                .long   _pre_handler
adr_abt_hdr:
                .long   _abt_handler
adr_irq_hdr:
                .long   jelly_irq_handler  // _irq_handler
adr_fiq_hdr:
                .long   fiq_handler


                .end


/* end of file */
