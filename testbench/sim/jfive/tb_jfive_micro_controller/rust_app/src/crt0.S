/* ------------------------------------------------------------------------ */
/*  startup                                                                 */
/*                                                                          */
/*                                          Copyright (C) 1998-2021 by Ryuz */
/* ------------------------------------------------------------------------ */


                .global     _rst_handler

                .extern     ___bss
                .extern     ___bss_end
                .extern     ___stack_end

                .extern     main


                .text

/************************************************
  リセットハンドラ
************************************************/
//                .align      4
_rst_handler:   
                lui     a1, %hi(0x12345678)
                addi    a1, a1, %lo(0x12345678)

                lui     sp, %hi(___stack_end)
                addi    sp, sp, %lo(___stack_end)

                /* main関数の呼び出し */
                jal     main
end_loop:
                j       end_loop


                .global   asm_test
asm_test:
                li	a0,7
                ret


/* end of file */
