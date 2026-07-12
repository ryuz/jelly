/* ------------------------------------------------------------------------ */
/*  startup                                                                 */
/*                                                                          */
/*                                          Copyright (C) 1998-2021 by Ryuji Fuchikami */
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
//              .align      4
_rst_handler:   
                j       start
sim_end:
                j       sim_end
sim_panic:
                j       sim_panic

start:
                lui     a1, %hi(0x12345678)
                addi    a1, a1, %lo(0x12345678)

                lui     sp, %hi(___stack_end)
                addi    sp, sp, %lo(___stack_end)

                /* main関数の呼び出し */
                jal     main
end_loop:
                j       sim_end

                .global   asm_panic
asm_panic:
                j       sim_panic


                .global   asm_test
asm_test:
                li	a0,7
                ret


/* end of file */
