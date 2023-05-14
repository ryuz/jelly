

`timescale 1ns / 1ps
`default_nettype none

module tb_sim_main
        #(
            parameter   int                             WB_ADR_WIDTH       = 16,
            parameter   int                             WB_DAT_WIDTH       = 32,
            parameter   int                             WB_SEL_WIDTH       = WB_DAT_WIDTH/8,

            parameter   int                             TMAX_TSKID         = 15,
            parameter   int                             TMAX_SEMID         = 7,
            parameter   int                             TSKPRI_WIDTH       = 4,
            parameter   int                             WUPCNT_WIDTH       = 1,
            parameter   int                             SUSCNT_WIDTH       = 1,
            parameter   int                             SEMCNT_WIDTH       = 4,
            parameter   int                             FLGPTN_WIDTH       = 32,
            parameter   int                             SYSTIM_WIDTH       = 64,
            parameter   int                             RELTIM_WIDTH       = 32,
            parameter   int                             TTS_WIDTH          = 4,
            parameter   int                             TTW_WIDTH          = 4,
            parameter   int                             QUECNT_WIDTH       = $clog2(TMAX_TSKID),
            parameter   int                             TSKID_WIDTH        = $clog2(TMAX_TSKID+1),
            parameter   int                             SEMID_WIDTH        = $clog2(TMAX_SEMID+1),
            parameter   int                             SCRATCH0_WIDTH     = WB_DAT_WIDTH,
            parameter   int                             SCRATCH1_WIDTH     = WB_DAT_WIDTH,
            parameter   int                             SCRATCH2_WIDTH     = WB_DAT_WIDTH,
            parameter   int                             SCRATCH3_WIDTH     = WB_DAT_WIDTH,

            parameter   bit                             USE_SLP_TSK        = 1,
            parameter   bit                             USE_SUS_TSK        = 1,
            parameter   bit                             USE_DLY_TSK        = 1,
            parameter   bit                             USE_REL_WAI        = 1,
            parameter   bit                             USE_SIG_SEM        = 1,
            parameter   bit                             USE_WAI_SEM        = 1,
            parameter   bit                             USE_POL_SEM        = 1,
            parameter   bit                             USE_WAI_FLG        = 1,
            parameter   bit                             USE_EXT_FLG        = 1,
            parameter   bit                             USE_REF_TSKSTAT    = 1,
            parameter   bit                             USE_REF_TSKWAIT    = 1,
            parameter   bit                             USE_REF_WUPCNT     = 1,
            parameter   bit                             USE_REF_SUSCNT     = 1,
            parameter   bit                             USE_REF_SEMCNT     = 1,
            parameter   bit                             USE_REF_SEMQUE     = 1,
            parameter   bit                             USE_REF_FLGPTN     = 1,
            parameter   bit                             USE_SCRATCH0       = 1,
            parameter   bit                             USE_SCRATCH1       = 1,
            parameter   bit                             USE_SCRATCH2       = 1,
            parameter   bit                             USE_SCRATCH3       = 1,

            parameter   bit     [FLGPTN_WIDTH-1:0]      INIT_FLGPTN        = '0,
            parameter   bit     [FLGPTN_WIDTH-1:0]      INIT_EXTFLG_ENABLE = '0,
            parameter   bit     [SCRATCH0_WIDTH-1:0]    INIT_SCRATCH0      = '0,
            parameter   bit     [SCRATCH1_WIDTH-1:0]    INIT_SCRATCH1      = '0,
            parameter   bit     [SCRATCH2_WIDTH-1:0]    INIT_SCRATCH2      = '0,
            parameter   bit     [SCRATCH3_WIDTH-1:0]    INIT_SCRATCH3      = '0
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

    logic   [FLGPTN_WIDTH-1:0]                  extflg_flgptn;

    logic   [TSKID_WIDTH-1:0]                   monitor_run_tskid;
    logic   [TSKID_WIDTH-1:0]                   monitor_top_tskid;
    logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       monitor_tsk_tskstat;
    logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       monitor_tsk_tskwait;
    logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    monitor_tsk_wupcnt;
    logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    monitor_tsk_suscnt;
    logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    monitor_sem_quecnt;
    logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    monitor_sem_semcnt;
    logic   [FLGPTN_WIDTH-1:0]                  monitor_flg_flgptn;
    logic   [SCRATCH0_WIDTH-1:0]                monitor_scratch0;
    logic   [SCRATCH1_WIDTH-1:0]                monitor_scratch1;
    logic   [SCRATCH2_WIDTH-1:0]                monitor_scratch2;
    logic   [SCRATCH3_WIDTH-1:0]                monitor_scratch3;
    
    jelly_rtos
            #(
                .WB_ADR_WIDTH           (WB_ADR_WIDTH       ),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH       ),
                .WB_SEL_WIDTH           (WB_SEL_WIDTH       ),
                .TMAX_TSKID             (TMAX_TSKID         ),
                .TMAX_SEMID             (TMAX_SEMID         ),
                .TSKPRI_WIDTH           (TSKPRI_WIDTH       ),
                .WUPCNT_WIDTH           (WUPCNT_WIDTH       ),
                .SUSCNT_WIDTH           (SUSCNT_WIDTH       ),
                .SEMCNT_WIDTH           (SEMCNT_WIDTH       ),
                .FLGPTN_WIDTH           (FLGPTN_WIDTH       ),
                .SYSTIM_WIDTH           (SYSTIM_WIDTH       ),
                .RELTIM_WIDTH           (RELTIM_WIDTH       ),
                .TTS_WIDTH              (TTS_WIDTH          ),
                .TTW_WIDTH              (TTW_WIDTH          ),
                .QUECNT_WIDTH           (QUECNT_WIDTH       ),
                .TSKID_WIDTH            (TSKID_WIDTH        ),
                .SEMID_WIDTH            (SEMID_WIDTH        ),
                .SCRATCH0_WIDTH         (SCRATCH0_WIDTH     ),
                .SCRATCH1_WIDTH         (SCRATCH1_WIDTH     ),
                .SCRATCH2_WIDTH         (SCRATCH2_WIDTH     ),
                .SCRATCH3_WIDTH         (SCRATCH3_WIDTH     ),
                .USE_SLP_TSK            (USE_SLP_TSK        ),
                .USE_SUS_TSK            (USE_SUS_TSK        ),
                .USE_DLY_TSK            (USE_DLY_TSK        ),
                .USE_REL_WAI            (USE_REL_WAI        ),
                .USE_SIG_SEM            (USE_SIG_SEM        ),
                .USE_WAI_SEM            (USE_WAI_SEM        ),
                .USE_POL_SEM            (USE_POL_SEM        ),
                .USE_WAI_FLG            (USE_WAI_FLG        ),
                .USE_EXT_FLG            (USE_EXT_FLG        ),
                .USE_REF_TSKSTAT        (USE_REF_TSKSTAT    ),
                .USE_REF_TSKWAIT        (USE_REF_TSKWAIT    ),
                .USE_REF_WUPCNT         (USE_REF_WUPCNT     ),
                .USE_REF_SUSCNT         (USE_REF_SUSCNT     ),
                .USE_REF_SEMCNT         (USE_REF_SEMCNT     ),
                .USE_REF_SEMQUE         (USE_REF_SEMQUE     ),
                .USE_REF_FLGPTN         (USE_REF_FLGPTN     ),
                .USE_SCRATCH0           (USE_SCRATCH0       ),
                .USE_SCRATCH1           (USE_SCRATCH1       ),
                .USE_SCRATCH2           (USE_SCRATCH2       ),
                .USE_SCRATCH3           (USE_SCRATCH3       ),
                .INIT_FLGPTN            (INIT_FLGPTN        ),
                .INIT_EXTFLG_ENABLE     (INIT_EXTFLG_ENABLE ),
                .INIT_SCRATCH0          (INIT_SCRATCH0      ),
                .INIT_SCRATCH1          (INIT_SCRATCH1      ),
                .INIT_SCRATCH2          (INIT_SCRATCH2      ),
                .INIT_SCRATCH3          (INIT_SCRATCH3      )
            )
        i_rtos
            (
                .*
            );

endmodule


`default_nettype wire


// end of file
