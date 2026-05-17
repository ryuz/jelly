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
                j       thread2_start
                j       thread3_start
                j       thread4_start
                j       thread5_start
                j       thread6_start
                j       thread7_start

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

thread2_start:
                lui     sp, %hi(___stack2_end)
                addi    sp, sp, %lo(___stack2_end)
                addi    a0, zero, 2
                jal     main
                j       end_loop

thread3_start:
                lui     sp, %hi(___stack3_end)
                addi    sp, sp, %lo(___stack3_end)
                addi    a0, zero, 3
                jal     main
                j       end_loop

thread4_start:
                lui     sp, %hi(___stack4_end)
                addi    sp, sp, %lo(___stack4_end)
                addi    a0, zero, 4
                jal     main
                j       end_loop

thread5_start:
                lui     sp, %hi(___stack5_end)
                addi    sp, sp, %lo(___stack5_end)
                addi    a0, zero, 5
                jal     main
                j       end_loop

thread6_start:
                lui     sp, %hi(___stack6_end)
                addi    sp, sp, %lo(___stack6_end)
                addi    a0, zero, 6
                jal     main
                j       end_loop

thread7_start:
                lui     sp, %hi(___stack7_end)
                addi    sp, sp, %lo(___stack7_end)
                addi    a0, zero, 7
                jal     main
                j       end_loop

end_loop:
                j       end_loop


/* end of file */
