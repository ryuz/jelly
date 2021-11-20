// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos
        #(
            parameter int   TASKS        = 16,
            parameter int   SEMAPHORES   = 4,
            parameter int   TSKPRI_WIDTH = 4,
            parameter int   SEMCNT_WIDTH = 4,
            parameter int   EVTFLG_WIDTH = 16,
            parameter int   SYSTIM_WIDTH = 64,
            parameter int   RELTIM_WIDTH = 32,

            parameter int   WB_ADR_WIDTH = 16,
            parameter int   WB_DAT_WIDTH = 32,
            parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  reg                         s_wb_ack_o,

            output  wire                        irq
        );


    // -----------------------------------------
    //  Core
    // -----------------------------------------

    localparam  int     TSKID_WIDTH  = $clog2(TASKS);
    localparam  int     SEMID_WIDTH  = $clog2(SEMAPHORES);

    // ready queue
    logic   [TSKID_WIDTH-1:0]   rdq_top_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_top_tskpri;
    logic                       rdq_top_valid;

    // task
    logic   [TSKID_WIDTH-1:0]   wup_tsk_tskid;
    logic                       wup_tsk_valid;

    logic   [TSKID_WIDTH-1:0]   slp_tsk_tskid;
    logic                       slp_tsk_valid;

    logic   [TSKID_WIDTH-1:0]   rel_wai_tskid;
    logic                       rel_wai_valid;
    

//    logic    [TASKS-1:0]         wai_flg;
//    logic    [0:0]               wai_flgmode;
//    logic    [EVTFLG_WIDTH-1:0]  wai_flgptn;

//    logic    [EVTFLG_WIDTH-1:0]  set_flg;
//    logic    [EVTFLG_WIDTH-1:0]  clr_flg;

    logic    [TSKID_WIDTH-1:0]   runtsk_tskid;
    logic                        runtsk_valid;

    jelly_rtos_core
            #(
                .TASKS          (TASKS),
                .SEMAPHORES     (SEMAPHORES)
            )
        i_rtos_core
            (
                .reset,
                .clk,
                .cke,

                .rdq_top_tskid,
                .rdq_top_tskpri,
                .rdq_top_valid,

                .wup_tsk_tskid,
                .wup_tsk_valid,

                .slp_tsk_tskid,
                .slp_tsk_valid,

                .rel_wai_tskid,
                .rel_wai_valid
            );



    
    // -----------------------------------------
    //  Wishbone
    // -----------------------------------------

    localparam  int                         OPCODE_WIDTH      = 8;
    localparam  int                         ID_WIDTH          = 8;
    localparam  int                         DECODE_OPCODE_POS = 0;
    localparam  int                         DECODE_ID_POS     = DECODE_OPCODE_POS + ID_WIDTH;

    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_INF  = 'h00;
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK  = 'h00;
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK  = 'h01;

    localparam  bit     [ID_WIDTH-1:0]      REF_INF_CORE_ID = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      REF_INF_VERSION = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      REF_INF_DATE    = 'h04;

    logic   [OPCODE_WIDTH-1:0]      dec_opcode;
    logic   [ID_WIDTH-1:0]          dec_id;
    assign  dec_opcode = s_wb_adr_i[DECODE_OPCODE_POS +: OPCODE_WIDTH];
    assign  dec_id     = s_wb_adr_i[DECODE_ID_POS     +: ID_WIDTH];


    always_comb begin : blk_wb
        s_wb_dat_o = '0;
        s_wb_ack_o = s_wb_stb_i;
        

        wup_tsk_tskid = 'x;
        wup_tsk_valid = '0;
        slp_tsk_tskid = 'x;
        slp_tsk_valid = '0;
        rel_wai_tskid = 'x;
        rel_wai_valid = '0;
        if ( s_wb_stb_i && s_wb_we_i ) begin
            case ( dec_opcode )
            OPCODE_WUP_TSK: begin wup_tsk_valid = 1'b1; wup_tsk_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SLP_TSK: begin slp_tsk_valid = 1'b1; slp_tsk_tskid = TSKID_WIDTH'(dec_id); end
            default: ;
            endcase
        end

        case ( dec_opcode )
        OPCODE_REF_INF:
            case ( dec_id )
            REF_INF_CORE_ID:    s_wb_dat_o = WB_DAT_WIDTH'(32'h834f5452);
            REF_INF_VERSION:    s_wb_dat_o = WB_DAT_WIDTH'(32'h00000000);
            REF_INF_DATE:       s_wb_dat_o = WB_DAT_WIDTH'(32'h20211120);
            default: ;
            endcase
        default:;
        endcase
    end


endmodule


`default_nettype wire


// End of file
