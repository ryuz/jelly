

`timescale 1ns / 1ps
//`default_nettype none


module tb_sim_main
        (
            input   logic                       reset,
            input   logic                       clk
        );

    parameter int                           QUE_SIZE        = 16;
    parameter int                           QUECNT_WIDTH    = $clog2(QUE_SIZE+1);
    parameter int                           TSKID_WIDTH     = 4;
    parameter int                           TSKPRI_WIDTH    = 4;
    parameter int                           SEMCNT_WIDTH    = 4;
    parameter bit                           PRIORITY_ORDER  = 1'b0;
    parameter bit   [SEMCNT_WIDTH-1:0]      INIT_SEMCNT     = '0;

    logic                           cke = 1'b1;

    logic                           sig_sem;
    logic                           pol_sem;
    logic                           pol_sem_ack;
    logic   [TSKID_WIDTH-1:0]       wai_sem_tskid;
    logic   [TSKPRI_WIDTH-1:0]      wai_sem_tskpri;
    logic                           wai_sem_valid;
    logic   [TSKID_WIDTH-1:0]       rel_wai_tskid;
    logic                           rel_wai_valid;
    logic   [TSKID_WIDTH-1:0]       wakeup_tskid;
    logic                           wakeup_valid;
    logic   [SEMCNT_WIDTH-1:0]      semcnt;
    logic   [QUECNT_WIDTH-1:0]      quecnt;

    jelly_rtos_semaphore
            #(
                .QUE_SIZE           (QUE_SIZE),
                .QUECNT_WIDTH       (QUECNT_WIDTH),
                .TSKID_WIDTH        (TSKID_WIDTH),
                .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                .PRIORITY_ORDER     (PRIORITY_ORDER),
                .INIT_SEMCNT        (INIT_SEMCNT)
            )
        i_rtos_semaphore
            (
                .*
            );

endmodule


//`default_nettype wire


// end of file
