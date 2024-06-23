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
//                .align      4
_rst_handler:   
                j       thread0_start
                j       thread1_start

thread0_start:
                lui     sp, %hi(___stack0_end)
                addi    sp, sp, %lo(___stack0_end)
                addi    a0, zero, 0
                jal     main
                j       end_loop

thread1_start:
                lui     sp, %hi(___stack1_end)
                addi    sp, sp, %lo(___stack1_end)
                addi    a0, zero, 1
                jal     main
                j       end_loop

end_loop:
                j       end_loop


/* end of file */
