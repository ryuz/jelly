/* ------------------------------------------------------------------------ */
/*  startup                                                                 */
/*                                                                          */
/*                               Copyright (C) 1998-2022 by Ryuji Fuchikami */
/* ------------------------------------------------------------------------ */


                .global     _rst_handler

                .extern     ___stack_end

                .extern     main


                .text

/************************************************
  リセットハンドラ
************************************************/
_rst_handler:   
                lui     sp, %hi(___stack_end)
                addi    sp, sp, %lo(___stack_end)

                /* main関数の呼び出し */
                jal     main
end_loop:
                j       end_loop



/* end of file */
