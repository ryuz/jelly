

`timescale 1ns / 1ps
//`default_nettype none


module tb_sim_main
        (
            input   logic                       reset,
            input   logic                       clk
        );


    parameter int                           QUE_SIZE        = 16;
    parameter int                           QUE_COUNT_WIDTH = $clog2(QUE_SIZE+1);
    parameter int                           TSKID_WIDTH     = 4;
    parameter int                           TSKPRI_WIDTH    = 4;
    parameter int                           SEM_COUNT_WIDTH = 4;
    parameter bit                           PRIORITY_ORDER  = 1'b0;
    parameter bit   [SEM_COUNT_WIDTH-1:0]   INIT_SEM_COUNT  = 0;

    logic                           cke = 1'b1;

    logic                           signal;

    logic   [TSKID_WIDTH-1:0]       wait_tskid;
    logic   [TSKPRI_WIDTH-1:0]      wait_tskpri;
    logic                           wait_valid;

    logic   [TSKID_WIDTH-1:0]       remove_tskid;
    logic                           remove_valid;

    logic   [TSKID_WIDTH-1:0]       wakeup_tskid;
    logic                           wakeup_valid;

    logic   [SEM_COUNT_WIDTH-1:0]   sem_count;
    logic   [QUE_COUNT_WIDTH-1:0]   que_count;

    jelly_rtos_semaphore
            #(
                .QUE_SIZE           (QUE_SIZE),
                .QUE_COUNT_WIDTH    (QUE_COUNT_WIDTH),
                .TSKID_WIDTH        (TSKID_WIDTH),
                .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                .SEM_COUNT_WIDTH    (SEM_COUNT_WIDTH),
                .PRIORITY_ORDER     (PRIORITY_ORDER),
                .INIT_SEM_COUNT     (INIT_SEM_COUNT)
            )
        i_rtos_semaphore
            (
                .*
            );

endmodule


//`default_nettype wire


// end of file
