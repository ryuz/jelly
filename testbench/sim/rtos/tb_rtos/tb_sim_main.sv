

`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        #(
            parameter   int                             WB_ADR_WIDTH     = 16,
            parameter   int                             WB_DAT_WIDTH     = 32,
            parameter   int                             WB_SEL_WIDTH     = WB_DAT_WIDTH/8,
    
            parameter   int                             TASKS            = 15,
            parameter   int                             SEMAPHORES       = 8,
            parameter   int                             TSKPRI_WIDTH     = 4,
            parameter   int                             SEMCNT_WIDTH     = 4,
            parameter   int                             FLGPTN_WIDTH     = 32,
            parameter   int                             SYSTIM_WIDTH     = 64,
            parameter   int                             RELTIM_WIDTH     = 32,

            parameter   int                             QUECNT_WIDTH     = $clog2(TASKS+1),
            parameter   int                             IDLE_TSKID_WIDTH = $clog2(TASKS+1),
            parameter   int                             TSKID_WIDTH      = $clog2(TASKS),
            parameter   int                             SEMID_WIDTH      = $clog2(SEMAPHORES),

            parameter   bit     [IDLE_TSKID_WIDTH-1:0]  INIT_IDLE_TSKID  = IDLE_TSKID_WIDTH'(TASKS),
            parameter   bit     [TSKID_WIDTH-1:0]       INIT_RUN_TSKID   = '0,
            parameter   bit     [FLGPTN_WIDTH-1:0]      INIT_FLGPTN      = '0
        )
        (
            input   wire                        reset,
            input   wire                        clk,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );

    logic                                       cke = 1'b1;
    logic                                       irq;

    logic   [IDLE_TSKID_WIDTH-1:0]              monitor_run_tskid;
    logic                                       monitor_run_valid;
    logic   [IDLE_TSKID_WIDTH-1:0]              monitor_top_tskid;
    logic                                       monitor_top_valid;
    logic   [SEMAPHORES-1:0][QUECNT_WIDTH-1:0]  monitor_sem_quecnt;
    logic   [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]  monitor_sem_semcnt;
    logic   [FLGPTN_WIDTH-1:0]                  monitor_flg_flgptn;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch0;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch1;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch2;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch3;

    jelly_rtos
            #(
                .WB_ADR_WIDTH       (WB_ADR_WIDTH),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
    
                .TASKS              (TASKS),
                .SEMAPHORES         (SEMAPHORES),
                .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                .SYSTIM_WIDTH       (SYSTIM_WIDTH),
                .RELTIM_WIDTH       (RELTIM_WIDTH),

                .QUECNT_WIDTH       (QUECNT_WIDTH),
                .IDLE_TSKID_WIDTH   (IDLE_TSKID_WIDTH),
                .TSKID_WIDTH        (TSKID_WIDTH),
                .SEMID_WIDTH        (SEMID_WIDTH),

                .INIT_IDLE_TSKID    (INIT_IDLE_TSKID),
                .INIT_RUN_TSKID     (INIT_RUN_TSKID),
                .INIT_FLGPTN        (INIT_FLGPTN)
            )
        i_rtos
            (
                .*
            );

endmodule


//`default_nettype wire


// end of file
