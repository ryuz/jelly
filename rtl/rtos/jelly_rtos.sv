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
            parameter   int                             WB_ADR_WIDTH        = 16,
            parameter   int                             WB_DAT_WIDTH        = 32,
            parameter   int                             WB_SEL_WIDTH        = WB_DAT_WIDTH/8,
       
            parameter   int                             TASKS               = 15,
            parameter   int                             SEMAPHORES          = 8,
            parameter   int                             TSKPRI_WIDTH        = 4,
            parameter   int                             SEMCNT_WIDTH        = 4,
            parameter   int                             FLGPTN_WIDTH        = 32,
            parameter   int                             SYSTIM_WIDTH        = 64,
            parameter   int                             RELTIM_WIDTH        = 32,
   
            parameter   int                             QUECNT_WIDTH        = $clog2(TASKS+1),
            parameter   int                             IDLE_TSKID_WIDTH    = $clog2(TASKS+1),
            parameter   int                             TSKID_WIDTH         = $clog2(TASKS),
            parameter   int                             SEMID_WIDTH         = $clog2(SEMAPHORES),
   
            parameter   bit     [IDLE_TSKID_WIDTH-1:0]  INIT_IDLE_TSKID     = IDLE_TSKID_WIDTH'(TASKS),
            parameter   bit     [TSKID_WIDTH-1:0]       INIT_RUN_TSKID      = '0,
            parameter   bit     [FLGPTN_WIDTH-1:0]      INIT_FLGPTN         = '0,
            parameter   bit     [FLGPTN_WIDTH-1:0]      INIT_EXT_FLG_ENABLE = '0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            input   wire    [WB_ADR_WIDTH-1:0]                  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]                  s_wb_dat_o,
            input   wire                                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]                  s_wb_sel_i,
            input   wire                                        s_wb_stb_i,
            output  reg                                         s_wb_ack_o,

            output  wire                                        irq,

            input   wire    [FLGPTN_WIDTH-1:0]                  ext_flg_flgptn,

            output  wire    [IDLE_TSKID_WIDTH-1:0]              monitor_run_tskid,
            output  wire                                        monitor_run_valid,
            output  wire    [IDLE_TSKID_WIDTH-1:0]              monitor_top_tskid,
            output  wire                                        monitor_top_valid,
            output  wire    [SEMAPHORES-1:0][QUECNT_WIDTH-1:0]  monitor_sem_quecnt,
            output  wire    [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]  monitor_sem_semcnt,
            output  wire    [FLGPTN_WIDTH-1:0]                  monitor_flg_flgptn,
            output  wire    [WB_DAT_WIDTH-1:0]                  monitor_scratch0,
            output  wire    [WB_DAT_WIDTH-1:0]                  monitor_scratch1,
            output  wire    [WB_DAT_WIDTH-1:0]                  monitor_scratch2,
            output  wire    [WB_DAT_WIDTH-1:0]                  monitor_scratch3

        );


    // -----------------------------------------
    //  Core
    // -----------------------------------------

    // system
    logic                                       core_reset;
    logic                                       core_busy;

    // ready queue
    logic   [TSKID_WIDTH-1:0]                   rdq_top_tskid;
    logic   [TSKPRI_WIDTH-1:0]                  rdq_top_tskpri;
    logic                                       rdq_top_valid;
    logic   [QUECNT_WIDTH-1:0]                  rdq_quecnt;

    // operation id
    logic   [TSKID_WIDTH-1:0]                   op_tskid;
    logic   [SEMID_WIDTH-1:0]                   op_semid;

    // task
    logic                                       wup_tsk_valid = '0;
    logic                                       slp_tsk_valid = '0;
    logic                                       rel_wai_valid = '0;
    logic   [RELTIM_WIDTH-1:0]                  dly_tsk_dlytim;
    logic                                       dly_tsk_valid = '0;
    logic   [TASKS-1:0][TSKPRI_WIDTH-1:0]       task_tskpri;
    logic   [TASKS-1:0][2:0]                    task_tskstat;

    // semaphore                
    logic                                       sig_sem_valid = '0;
    logic                                       wai_sem_valid = '0;
    logic                                       pol_sem_valid = '0;
    logic                                       pol_sem_ack;
    logic   [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]  semaphore_semcnt;
    logic   [SEMAPHORES-1:0][QUECNT_WIDTH-1:0]  semaphore_quecnt;

    // event flag
    logic   [FLGPTN_WIDTH-1:0]                  set_flg;
    logic   [FLGPTN_WIDTH-1:0]                  clr_flg;
    logic   [0:0]                               wai_flg_wfmode;
    logic   [FLGPTN_WIDTH-1:0]                  wai_flg_flgptn;
    logic                                       wai_flg_valid;
    logic   [FLGPTN_WIDTH-1:0]                  flg_flgptn;

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
                .reset          (core_reset),
                .clk,
                .cke,
                
                .busy           (core_busy),     

                .rdq_top_tskid,
                .rdq_top_tskpri,
                .rdq_top_valid,
                .rdq_quecnt,

                .op_tskid,
                .op_semid,

                .wup_tsk_valid,
                .slp_tsk_valid,
                .rel_wai_valid,
                .dly_tsk_dlytim,
                .dly_tsk_valid,
                .task_tskpri,
                .task_tskstat,

                .sig_sem_valid,
                .wai_sem_valid,
                .pol_sem_valid,
                .pol_sem_ack,
                .semaphore_quecnt,
                .semaphore_semcnt,

                .set_flg,
                .clr_flg,
                .wai_flg_wfmode,
                .wai_flg_flgptn,
                .wai_flg_valid,
                .flg_flgptn
            );
    
    // -----------------------------------------
    //  Wishbone
    // -----------------------------------------

    localparam  int                         ID_WIDTH          = 8;
    localparam  int                         OPCODE_WIDTH      = 8;
    localparam  int                         DECODE_ID_POS     = 0;
    localparam  int                         DECODE_OPCODE_POS = DECODE_ID_POS + ID_WIDTH;

    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYS_CFG     = OPCODE_WIDTH'(8'h00);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CPU_CTL     = OPCODE_WIDTH'(8'h01);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK     = OPCODE_WIDTH'(8'h10);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK     = OPCODE_WIDTH'(8'h11);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK     = OPCODE_WIDTH'(8'h18);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM     = OPCODE_WIDTH'(8'h21);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM     = OPCODE_WIDTH'(8'h22);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_POL_SEM     = OPCODE_WIDTH'(8'h23);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SEMCNT  = OPCODE_WIDTH'(8'h28);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG     = OPCODE_WIDTH'(8'h31);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG     = OPCODE_WIDTH'(8'h32);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND = OPCODE_WIDTH'(8'h33);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR  = OPCODE_WIDTH'(8'h34);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_ENA_FLG_EXT = OPCODE_WIDTH'(8'h3a);

    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_CORE_ID      = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_VERSION      = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_DATE         = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TASKS        = 'h20;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SEMAPHORES   = 'h21;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TSKPRI_WIDTH = 'h30;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SEMCNT_WIDTH = 'h31;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_FLGPTN_WIDTH = 'h32;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SYSTIM_WIDTH = 'h34;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_RELTIM_WIDTH = 'h35;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SOFT_RESET   = 'hff;

    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_TSKID  = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_VALID  = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_TSKID  = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_VALID  = 'h05;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IDLE_TSKID = 'h07;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_COPY_TSKID = 'h08;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_EN     = 'h10;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_STS    = 'h11;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_FORCE  = 'h1f;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH0   = 'he0;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH1   = 'he1;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH2   = 'he2;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH3   = 'he3;


    logic   [OPCODE_WIDTH-1:0]      dec_opcode;
    logic   [ID_WIDTH-1:0]          dec_id;
    assign  dec_opcode = s_wb_adr_i[DECODE_OPCODE_POS +: OPCODE_WIDTH];
    assign  dec_id     = s_wb_adr_i[DECODE_ID_POS     +: ID_WIDTH];
                            
    logic   [TSKID_WIDTH-1:0]           cpu_run_tskid;
    logic                               cpu_run_valid;
    logic   [IDLE_TSKID_WIDTH-1:0]      cpu_idle_tskid;

    logic   [0:0]                       irq_enable;
    logic   [0:0]                       irq_force;
    logic   [0:0]                       reg_switch;
    logic   [0:0]                       reg_irq;

    logic   [FLGPTN_WIDTH-1:0]          ext_flg_enable;

    logic   [WB_DAT_WIDTH-1:0]          scratch0;
    logic   [WB_DAT_WIDTH-1:0]          scratch1;
    logic   [WB_DAT_WIDTH-1:0]          scratch2;
    logic   [WB_DAT_WIDTH-1:0]          scratch3;

    logic    [IDLE_TSKID_WIDTH-1:0]     cur_run_tskid;
    logic                               cur_run_valid;
    logic    [IDLE_TSKID_WIDTH-1:0]     cur_top_tskid;
    logic                               cur_top_valid;
    assign cur_top_tskid = rdq_top_valid ? IDLE_TSKID_WIDTH'(rdq_top_tskid) : cpu_idle_tskid;
    assign cur_top_valid = rdq_top_valid;
    assign cur_run_tskid = cpu_run_valid ? IDLE_TSKID_WIDTH'(cpu_run_tskid) : cpu_idle_tskid;
    assign cur_run_valid = cpu_run_valid;

    always_ff @(posedge clk) begin
        if ( reset || core_reset ) begin
            core_reset     <= reset;
            cpu_run_tskid  <= '0;
            cpu_run_valid  <= '0;
            cpu_idle_tskid <= INIT_IDLE_TSKID;
            irq_enable     <= '0;
            irq_force      <= '0;
            reg_switch     <= '0;
            reg_irq        <= '0;
            ext_flg_enable <= INIT_EXT_FLG_ENABLE;
            scratch0       <= '0;
            scratch1       <= '0;
            scratch2       <= '0;
            scratch3       <= '0;
        end
        else if ( cke ) begin
            core_reset <= 1'b0;

            if ( s_wb_ack_o && s_wb_we_i && &s_wb_sel_i ) begin
                case ( dec_opcode )
                OPCODE_SYS_CFG:
                    case ( dec_id )
                    SYS_CFG_SOFT_RESET: begin core_reset <= 1'b1; end
                    default: ;
                    endcase

                OPCODE_CPU_CTL:
                    case ( dec_id )
                    CPU_CTL_RUN_TSKID:  begin cpu_run_tskid  <= TSKID_WIDTH'(s_wb_dat_i); cpu_run_valid <= (s_wb_dat_i < TASKS); end
                    CPU_CTL_RUN_VALID:  begin cpu_run_valid  <= 1'(s_wb_dat_i); end
                    CPU_CTL_IDLE_TSKID: begin cpu_idle_tskid <= IDLE_TSKID_WIDTH'(s_wb_dat_i); end
                    CPU_CTL_COPY_TSKID: begin cpu_run_tskid  <= IDLE_TSKID_WIDTH'(s_wb_dat_i); cpu_run_valid <= (s_wb_dat_i < TASKS); end
                    CPU_CTL_IRQ_EN:     begin irq_enable     <= 1'(s_wb_dat_i); end
                    CPU_CTL_IRQ_FORCE:  begin irq_force      <= 1'(s_wb_dat_i); end
                    CPU_CTL_SCRATCH0:   begin scratch0       <= s_wb_dat_i; end
                    CPU_CTL_SCRATCH1:   begin scratch1       <= s_wb_dat_i; end
                    CPU_CTL_SCRATCH2:   begin scratch2       <= s_wb_dat_i; end
                    CPU_CTL_SCRATCH3:   begin scratch3       <= s_wb_dat_i; end
                    default: ;
                    endcase

                OPCODE_ENA_FLG_EXT: begin ext_flg_enable <= FLGPTN_WIDTH'(s_wb_dat_i); end

                default: ;
                endcase

            end

            // 読み出しでコピー実施
            if ( s_wb_ack_o && !s_wb_we_i && dec_opcode == OPCODE_CPU_CTL && dec_id == CPU_CTL_COPY_TSKID ) begin
                cpu_run_tskid <= rdq_top_tskid;
                cpu_run_valid <= rdq_top_valid;
            end

            if ( !core_busy ) begin
                reg_switch <= (cur_top_tskid != cur_run_tskid);
                reg_irq    <= (cur_top_tskid != cur_run_tskid) && reg_switch;
            end
        end
    end
    
    assign irq = (reg_irq & irq_enable) | irq_force;

    always_comb begin : blk_wb_cmd
        op_tskid = 'x;
        op_semid = 'x;

        wup_tsk_valid = '0;
        slp_tsk_valid = '0;
        rel_wai_valid = '0;
        dly_tsk_dlytim = 'x;
        dly_tsk_valid  = '0;

        sig_sem_valid = '0;
        wai_sem_valid = '0;
        pol_sem_valid = '0;

        set_flg        = '0;
        clr_flg        = '1;
        wai_flg_wfmode = 'x;
        wai_flg_flgptn = 'x;
        wai_flg_valid  = '0;

        // write
        if ( s_wb_ack_o && s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_WUP_TSK:     begin wup_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SLP_TSK:     begin slp_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SET_FLG:     begin set_flg = FLGPTN_WIDTH'(s_wb_dat_i); end
            OPCODE_CLR_FLG:     begin clr_flg = FLGPTN_WIDTH'(s_wb_dat_i); end

            OPCODE_DLY_TSK:
                begin
                    dly_tsk_valid  = 1'b1;
                    op_tskid       = TSKID_WIDTH'(dec_id);
                    dly_tsk_dlytim = RELTIM_WIDTH'(s_wb_dat_i);
                end

            OPCODE_SIG_SEM:     begin sig_sem_valid = 1'b1; op_semid = SEMID_WIDTH'(dec_id);  end
            OPCODE_WAI_SEM:     begin wai_sem_valid = 1'b1; op_semid = SEMID_WIDTH'(dec_id); op_tskid = rdq_top_tskid; end

            OPCODE_WAI_FLG_AND:
                begin
                    wai_flg_valid  = 1'b1;
                    wai_flg_flgptn = FLGPTN_WIDTH'(s_wb_dat_i);
                    wai_flg_wfmode = 1'b0;
                end
            
            OPCODE_WAI_FLG_OR:
                begin
                    wai_flg_valid  = 1'b1;
                    wai_flg_flgptn = FLGPTN_WIDTH'(s_wb_dat_i);
                    wai_flg_wfmode = 1'b1;
                end
            
            default: ;
            endcase
        end

        // read
        if ( s_wb_ack_o && !s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_POL_SEM:     begin pol_sem_valid = 1'b1; op_semid = SEMID_WIDTH'(dec_id);  end
            default: ;
            endcase
        end

        // external flag
        set_flg = set_flg | (ext_flg_enable & ext_flg_flgptn);
    end

    // wishbone read
    always_comb begin : blk_wb_dat_o
        s_wb_dat_o = '0;

        case ( dec_opcode )
        OPCODE_SYS_CFG:
            case ( dec_id )
            SYS_CFG_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(32'h834f5452);
            SYS_CFG_VERSION:        s_wb_dat_o = WB_DAT_WIDTH'(32'h00000000);
            SYS_CFG_DATE:           s_wb_dat_o = WB_DAT_WIDTH'(32'h20211120);
            SYS_CFG_TASKS:          s_wb_dat_o = WB_DAT_WIDTH'(TASKS);
            SYS_CFG_SEMAPHORES:     s_wb_dat_o = WB_DAT_WIDTH'(SEMAPHORES);
            SYS_CFG_TSKPRI_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(TSKPRI_WIDTH);
            SYS_CFG_SEMCNT_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SEMCNT_WIDTH);
            SYS_CFG_FLGPTN_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(FLGPTN_WIDTH);
            SYS_CFG_SYSTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SYSTIM_WIDTH);
            SYS_CFG_RELTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(RELTIM_WIDTH);
            default: ;
            endcase

        OPCODE_CPU_CTL:
            case ( dec_id )
            CPU_CTL_TOP_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_top_tskid);
            CPU_CTL_TOP_VALID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_top_valid);
            CPU_CTL_RUN_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_run_tskid);
            CPU_CTL_RUN_VALID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_run_valid);
            CPU_CTL_IDLE_TSKID: s_wb_dat_o = WB_DAT_WIDTH'(cpu_idle_tskid);
            CPU_CTL_COPY_TSKID: s_wb_dat_o = WB_DAT_WIDTH'(cur_top_tskid);
            CPU_CTL_IRQ_EN:     s_wb_dat_o = WB_DAT_WIDTH'(irq_enable);
            CPU_CTL_IRQ_STS:    s_wb_dat_o = WB_DAT_WIDTH'(irq);
            CPU_CTL_SCRATCH0:   s_wb_dat_o = WB_DAT_WIDTH'(scratch0);
            CPU_CTL_SCRATCH1:   s_wb_dat_o = WB_DAT_WIDTH'(scratch1);
            CPU_CTL_SCRATCH2:   s_wb_dat_o = WB_DAT_WIDTH'(scratch2);
            CPU_CTL_SCRATCH3:   s_wb_dat_o = WB_DAT_WIDTH'(scratch3);
            default: ;
            endcase
        
        OPCODE_POL_SEM:     s_wb_dat_o = WB_DAT_WIDTH'(pol_sem_ack);
        OPCODE_REF_SEMCNT:  s_wb_dat_o = WB_DAT_WIDTH'(semaphore_semcnt);
        default: ;
        endcase
    end

    assign  s_wb_ack_o = s_wb_stb_i && !core_busy;


    /*
    always_comb begin : blk_wb_cmd
        s_wb_dat_o = '0;
        s_wb_ack_o = s_wb_stb_i && !core_busy;
        
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
        pol_sem_semid = 'x;
        pol_sem_valid = '0;

        set_flg        = '0;
        clr_flg        = '1;
        wai_flg_wfmode = 'x;
        wai_flg_flgptn = 'x;
        wai_flg_valid  = '0;

        // write
        if ( s_wb_ack_o && s_wb_we_i && &s_wb_sel_i ) begin
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

        // read
        if ( s_wb_ack_o && !s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_POL_SEM:     begin pol_sem_semid = SEMID_WIDTH'(dec_id); pol_sem_valid = (int'(dec_id) < SEMAPHORES); end
            default: ;
            endcase
        end

        case ( dec_opcode )
        OPCODE_SYS_CFG:
            case ( dec_id )
            SYS_CFG_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(32'h834f5452);
            SYS_CFG_VERSION:        s_wb_dat_o = WB_DAT_WIDTH'(32'h00000000);
            SYS_CFG_DATE:           s_wb_dat_o = WB_DAT_WIDTH'(32'h20211120);
            SYS_CFG_TASKS:          s_wb_dat_o = WB_DAT_WIDTH'(TASKS);
            SYS_CFG_SEMAPHORES:     s_wb_dat_o = WB_DAT_WIDTH'(SEMAPHORES);
            SYS_CFG_TSKPRI_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(TSKPRI_WIDTH);
            SYS_CFG_SEMCNT_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SEMCNT_WIDTH);
            SYS_CFG_FLGPTN_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(FLGPTN_WIDTH);
            SYS_CFG_SYSTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SYSTIM_WIDTH);
            SYS_CFG_RELTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(RELTIM_WIDTH);
            default: ;
            endcase

        OPCODE_CPU_CTL:
            case ( dec_id )
            CPU_CTL_TOP_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_top_tskid);
            CPU_CTL_TOP_VALID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_top_valid);
            CPU_CTL_RUN_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_run_tskid);
            CPU_CTL_RUN_VALID:  s_wb_dat_o = WB_DAT_WIDTH'(cur_run_valid);
            CPU_CTL_IDLE_TSKID: s_wb_dat_o = WB_DAT_WIDTH'(cpu_idle_tskid);
            CPU_CTL_COPY_TSKID: s_wb_dat_o = WB_DAT_WIDTH'(cur_run_tskid);
            CPU_CTL_IRQ_EN:     s_wb_dat_o = WB_DAT_WIDTH'(irq_enable);
            CPU_CTL_IRQ_STS:    s_wb_dat_o = WB_DAT_WIDTH'(irq);
            CPU_CTL_SCRATCH0:   s_wb_dat_o = WB_DAT_WIDTH'(scratch0);
            CPU_CTL_SCRATCH1:   s_wb_dat_o = WB_DAT_WIDTH'(scratch1);
            CPU_CTL_SCRATCH2:   s_wb_dat_o = WB_DAT_WIDTH'(scratch2);
            CPU_CTL_SCRATCH3:   s_wb_dat_o = WB_DAT_WIDTH'(scratch3);
            default: ;
            endcase
        
//      OPCODE_POL_SEM:     s_wb_dat_o = WB_DAT_WIDTH'(pol_sem_ack);
        OPCODE_REF_SEMCNT:  s_wb_dat_o = WB_DAT_WIDTH'(sem_semcnt);
        default: ;
        endcase

        // external flag
        set_flg |= (ext_flg_enable & ext_flg_flgptn);
    end
    */

    assign monitor_top_tskid  = cur_top_tskid;
    assign monitor_top_valid  = cur_top_valid;
    assign monitor_run_tskid  = cur_run_tskid;
    assign monitor_run_valid  = cur_run_valid;
    assign monitor_sem_quecnt = semaphore_quecnt;
    assign monitor_sem_semcnt = semaphore_semcnt;
    assign monitor_flg_flgptn = flg_flgptn;
    assign monitor_scratch0   = scratch0;
    assign monitor_scratch1   = scratch1;
    assign monitor_scratch2   = scratch2;
    assign monitor_scratch3   = scratch3;
    
endmodule


`default_nettype wire


// End of file
