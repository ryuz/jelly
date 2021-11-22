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
            parameter   int                         WB_ADR_WIDTH = 16,
            parameter   int                         WB_DAT_WIDTH = 32,
            parameter   int                         WB_SEL_WIDTH = WB_DAT_WIDTH/8,

            parameter   int                         TASKS        = 16,
            parameter   int                         SEMAPHORES   = 8,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMCNT_WIDTH = 4,
            parameter   int                         FLGPTN_WIDTH = 32,
            parameter   int                         SYSTIM_WIDTH = 64,
            parameter   int                         RELTIM_WIDTH = 32,

            parameter   bit     [FLGPTN_WIDTH-1:0]  INIT_FLGPTN  = '0
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
    logic                       wup_tsk_valid = '0;

    logic   [TSKID_WIDTH-1:0]   slp_tsk_tskid;
    logic                       slp_tsk_valid = '0;

    logic   [TSKID_WIDTH-1:0]   rel_wai_tskid;
    logic                       rel_wai_valid = '0;

    logic   [TSKID_WIDTH-1:0]   dly_tsk_tskid;
    logic   [RELTIM_WIDTH-1:0]  dly_tsk_dlytim;
    logic                       dly_tsk_valid = '0;

    // semaphore
    logic   [SEMID_WIDTH-1:0]   sig_sem_semid;
    logic                       sig_sem_valid = '0;

    logic   [SEMID_WIDTH-1:0]   wai_sem_semid;
    logic                       wai_sem_valid = '0;

    // event flag
    logic   [FLGPTN_WIDTH-1:0]  evtflg_flgptn;
    logic   [FLGPTN_WIDTH-1:0]  set_flg;
    logic   [FLGPTN_WIDTH-1:0]  clr_flg;
    logic   [0:0]               wai_flg_wfmode;
    logic   [FLGPTN_WIDTH-1:0]  wai_flg_flgptn;
    logic                       wai_flg_valid;

    jelly_rtos_core
            #(
                .TASKS          (TASKS),
                .SEMAPHORES     (SEMAPHORES),
                .TSKPRI_WIDTH   (TSKPRI_WIDTH),
                .SEMCNT_WIDTH   (SEMCNT_WIDTH),
                .FLGPTN_WIDTH   (FLGPTN_WIDTH),
                .SYSTIM_WIDTH   (SYSTIM_WIDTH),
                .RELTIM_WIDTH   (RELTIM_WIDTH),
                .TSKID_WIDTH    (TSKID_WIDTH),
                .SEMID_WIDTH    (SEMID_WIDTH),
                .INIT_FLGPTN    (INIT_FLGPTN)
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
                .rel_wai_valid,

                .dly_tsk_tskid,
                .dly_tsk_dlytim,
                .dly_tsk_valid,

                .sig_sem_semid,
                .sig_sem_valid,
                .wai_sem_semid,
                .wai_sem_valid,

                .evtflg_flgptn,
                .set_flg,
                .clr_flg,
                .wai_flg_wfmode,
                .wai_flg_flgptn,
                .wai_flg_valid
            );

    
    // -----------------------------------------
    //  Wishbone
    // -----------------------------------------

    localparam  int                         ID_WIDTH          = 8;
    localparam  int                         OPCODE_WIDTH      = 8;
    localparam  int                         DECODE_ID_POS     = 0;
    localparam  int                         DECODE_OPCODE_POS = DECODE_ID_POS + ID_WIDTH;

    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_CFG     = OPCODE_WIDTH'(8'h00);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CPU_CTL     = OPCODE_WIDTH'(8'h01);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK     = OPCODE_WIDTH'(8'h10);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK     = OPCODE_WIDTH'(8'h11);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK     = OPCODE_WIDTH'(8'h18);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM     = OPCODE_WIDTH'(8'h21);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM     = OPCODE_WIDTH'(8'h22);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG     = OPCODE_WIDTH'(8'h31);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG     = OPCODE_WIDTH'(8'h32);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND = OPCODE_WIDTH'(8'h33);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR  = OPCODE_WIDTH'(8'h34);

    localparam  bit     [ID_WIDTH-1:0]      REF_CFG_CORE_ID = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      REF_CFG_VERSION = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      REF_CFG_DATE    = 'h04;

    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_TSKID   = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_VALID   = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_TSKID   = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_VALID   = 'h05;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_EN      = 'h10;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_STS     = 'h11;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_FORCE   = 'h1f;

    logic   [OPCODE_WIDTH-1:0]      dec_opcode;
    logic   [ID_WIDTH-1:0]          dec_id;
    assign  dec_opcode = s_wb_adr_i[DECODE_OPCODE_POS +: OPCODE_WIDTH];
    assign  dec_id     = s_wb_adr_i[DECODE_ID_POS     +: ID_WIDTH];

    logic   [0:0]                   irq_enable;
    logic   [0:0]                   irq_force;

    logic   [TSKID_WIDTH-1:0]       cpu_tskid;
    logic                           cpu_valid;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            irq_enable <= '0;
            irq_force  <= '0;
            cpu_tskid  <= '0;
            cpu_valid  <= '0;
        end
        else if ( cke ) begin
            if ( s_wb_stb_i && s_wb_we_i && &s_wb_sel_i ) begin
                case ( dec_opcode )
                OPCODE_CPU_CTL:
                    case ( dec_id )
                    CPU_CTL_IRQ_EN:     begin irq_enable <= 1'(s_wb_dat_i); end
                    CPU_CTL_IRQ_FORCE:  begin irq_force  <= 1'(s_wb_dat_i); end
                    CPU_CTL_RUN_TSKID:  begin cpu_tskid <= TSKID_WIDTH'(s_wb_dat_i); cpu_valid <= 1'b1; end
                    CPU_CTL_RUN_VALID:  begin cpu_valid <= s_wb_dat_i[0]; end
                    default: ;
                    endcase
                default: ;
                endcase
            end
        end
    end

    always_comb begin : blk_wb
        s_wb_dat_o = '0;
        s_wb_ack_o = s_wb_stb_i;
        
        wup_tsk_tskid = 'x;
        wup_tsk_valid = '0;
        slp_tsk_tskid = 'x;
        slp_tsk_valid = '0;
        rel_wai_tskid = 'x;
        rel_wai_valid = '0;

        dly_tsk_tskid  = 'x;
        dly_tsk_dlytim = 'x;
        dly_tsk_valid  = '0;

        sig_sem_semid = 'x;
        sig_sem_valid = '0;
        wai_sem_semid = 'x;
        wai_sem_valid = '0;

        set_flg        = '0;
        clr_flg        = '1;
        wai_flg_wfmode = 'x;
        wai_flg_flgptn = 'x;
        wai_flg_valid  = '0;

        if ( s_wb_stb_i && s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_WUP_TSK:     begin wup_tsk_tskid = TSKID_WIDTH'(dec_id); wup_tsk_valid = (int'(dec_id) < TASKS); end
            OPCODE_SLP_TSK:     begin slp_tsk_tskid = TSKID_WIDTH'(dec_id); slp_tsk_valid = (int'(dec_id) < TASKS); end
            OPCODE_SET_FLG:     begin set_flg = FLGPTN_WIDTH'(s_wb_dat_i); end
            OPCODE_CLR_FLG:     begin clr_flg = FLGPTN_WIDTH'(s_wb_dat_i); end

            OPCODE_DLY_TSK:
                begin
                    dly_tsk_tskid  = TSKID_WIDTH'(dec_id);
                    dly_tsk_dlytim = RELTIM_WIDTH'(s_wb_dat_i);
                    dly_tsk_valid  = (int'(dec_id) < TASKS);
                end

            OPCODE_SIG_SEM:     begin sig_sem_semid = SEMID_WIDTH'(dec_id); sig_sem_valid = (int'(dec_id) < SEMAPHORES); end
            OPCODE_WAI_SEM:     begin wai_sem_semid = SEMID_WIDTH'(dec_id); wai_sem_valid = (int'(dec_id) < SEMAPHORES); end

            OPCODE_WAI_FLG_AND:
                begin
                    wai_flg_flgptn = FLGPTN_WIDTH'(s_wb_dat_i);
                    wai_flg_wfmode = 1'b0;
                    wai_flg_valid  = 1'b1;
                end
            
            OPCODE_WAI_FLG_OR:
                begin
                    wai_flg_flgptn = FLGPTN_WIDTH'(s_wb_dat_i);
                    wai_flg_wfmode = 1'b1;
                    wai_flg_valid  = 1'b1;
                end
            
            default: ;
            endcase
        end

        case ( dec_opcode )
        OPCODE_CPU_CTL:
            case ( dec_id )
            CPU_CTL_IRQ_EN:     s_wb_dat_o = WB_DAT_WIDTH'(irq_enable);
            CPU_CTL_IRQ_STS:    s_wb_dat_o = WB_DAT_WIDTH'(irq);
            CPU_CTL_TOP_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(rdq_top_tskid);
            CPU_CTL_TOP_VALID:  s_wb_dat_o = WB_DAT_WIDTH'(rdq_top_valid);
            default: ;
            endcase
        
        OPCODE_REF_CFG:
            case ( dec_id )
            REF_CFG_CORE_ID:    s_wb_dat_o = WB_DAT_WIDTH'(32'h834f5452);
            REF_CFG_VERSION:    s_wb_dat_o = WB_DAT_WIDTH'(32'h00000000);
            REF_CFG_DATE:       s_wb_dat_o = WB_DAT_WIDTH'(32'h20211120);
            default: ;
            endcase
        default:;
        endcase
    end

    assign irq = (irq_enable && cpu_valid && rdq_top_valid && (rdq_top_tskid != cpu_tskid)) | irq_force;

endmodule


`default_nettype wire


// End of file
