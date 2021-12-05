// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_rtos_task
        #(
            parameter   int                         TSKID_WIDTH  = 4,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMID_WIDTH  = 4,
            parameter   int                         TMAX_FLGID   = 1,
            parameter   int                         FLGPTN_WIDTH = 4,
            parameter   int                         RELTIM_WIDTH = 32,
            parameter   int                         WUPCNT_WIDTH = 1,
            parameter   int                         SUSCNT_WIDTH = 1,
            parameter   int                         ER_WIDTH     = 8,
            parameter   int                         TTS_WIDTH    = 4,
            parameter   int                         TTW_WIDTH    = 4,
            parameter   bit     [TSKID_WIDTH-1:0]   TSKID        = 0,
            parameter   bit     [WUPCNT_WIDTH-1:0]  TMAX_WUPCNT  = '1,
            parameter   bit     [SUSCNT_WIDTH-1:0]  TMAX_SUSCNT  = '1,
            parameter   bit                         USE_ER       = 1,
            parameter   bit                         USE_CHG_PRI  = 1,
            parameter   bit                         USE_SLP_TSK  = 1,
            parameter   bit                         USE_SUS_TSK  = 1,
            parameter   bit                         USE_DLY_TSK  = 1,
            parameter   bit                         USE_REL_WAI  = 1,
            parameter   bit                         USE_WAI_SEM  = 1,
            parameter   bit                         USE_WAI_FLG  = 1,
            parameter   bit                         USE_SET_TMO  = 1,
            parameter   bit     [TSKPRI_WIDTH-1:0]  INIT_TSKPRI  = TSKPRI_WIDTH'(TSKID)
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            input   wire                                        time_tick,

            output  wire                                        busy,


            output  reg                                         rdq_add_req,
            input   wire                                        rdq_add_ack,

            output  reg                                         rdq_rmv,

            output  reg                                         timeout_req,
            input   wire                                        timeout_ack,

            input   wire                                        rel_tsk,

            output  reg     [TTS_WIDTH-1:0]                     tskstat,
            output  reg     [TTW_WIDTH-1:0]                     tskwait,
            output  reg     [WUPCNT_WIDTH-1:0]                  wupcnt,
            output  reg     [SUSCNT_WIDTH-1:0]                  suscnt,
            output  reg     [TSKPRI_WIDTH-1:0]                  tskpri,
            output  reg     [RELTIM_WIDTH-1:0]                  timcnt,
            output  wire    [ER_WIDTH-1:0]                      er,

            input   wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    flgptn,
            
            input   wire    [TSKID_WIDTH-1:0]                   run_tskid,
            input   wire    [TSKID_WIDTH-1:0]                   op_tskid,
            input   wire    [TSKPRI_WIDTH-1:0]                  chg_pri_tskpri,
            input   wire                                        chg_pri_valid,
            input   wire                                        wup_tsk_valid,
            input   wire                                        slp_tsk_valid,
            input   wire                                        sus_tsk_valid,
            input   wire                                        rsm_tsk_valid,
            input   wire    [RELTIM_WIDTH-1:0]                  dly_tsk_dlytim,
            input   wire                                        dly_tsk_valid,
            input   wire                                        rel_wai_valid,
            input   wire                                        wai_sem_valid,
            input   wire    [0:0]                               wai_flg_wfmode,
            input   wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    wai_flg_flgptn,
            input   wire                                        wai_flg_valid,
            input   wire    [RELTIM_WIDTH-1:0]                  set_tmo_tmotim,
            input   wire                                        set_tmo_valid
        );


    logic                       run_valid;
    logic                       op_valid;

    logic                       chg_pri;
    logic                       wup_tsk;
    logic                       slp_tsk;
    logic                       sus_tsk;
    logic                       rsm_tsk;
    logic                       dly_tsk;
    logic                       rel_wai;
    logic                       wai_sem;
    logic                       wai_flg;
    logic                       set_tmo;

    assign run_valid = (run_tskid  == TSKID);
    assign op_valid  = (op_tskid  == TSKID);

    assign chg_pri = chg_pri_valid & op_valid & USE_CHG_PRI;
    assign wup_tsk = wup_tsk_valid & op_valid & USE_SLP_TSK;
    assign slp_tsk = slp_tsk_valid & op_valid & USE_SLP_TSK;
    assign sus_tsk = sus_tsk_valid & op_valid & USE_SUS_TSK;
    assign rsm_tsk = rsm_tsk_valid & op_valid & USE_SUS_TSK;
    assign dly_tsk = dly_tsk_valid & op_valid & USE_DLY_TSK;
    assign rel_wai = rel_wai_valid & op_valid & USE_REL_WAI;
    assign wai_sem = wai_sem_valid & op_valid & USE_WAI_SEM; 
    assign wai_flg = wai_flg_valid & op_valid & USE_WAI_FLG; 
    assign set_tmo = set_tmo_valid & op_valid & USE_SET_TMO;

    typedef enum bit signed [ER_WIDTH-1:0] {
        E_OK    = 0,
        E_OBJ   = -41,
        E_QOVR  = -43,
        E_RLWAI = -49,
        E_TMOUT = -50
    } er_t;

    typedef enum bit [TTS_WIDTH-1:0] {
        TTS_RUN = 'h1,
        TTS_RDY = 'h2, 
        TTS_WAI = 'h4,
        TTS_SUS = 'h8,
        TTS_WAS = 'hc
    } tskstat_t;

    typedef enum bit [TTW_WIDTH-1:0] {
        TTW_SLP = 'h1,
        TTW_DLY = 'h2,
        TTS_SEM = 'h4,
        TTS_FLG = 'h8
    } tskwait_t;

    logic                                       tskstat_run;
    logic                                       tskstat_rdy;
    logic                                       tskstat_wai;
    logic                                       tskstat_sus;
    logic                                       tskwait_slp;
    logic                                       tskwait_dly;
    logic                                       tskwait_sem;
    logic                                       tskwait_flg;

    logic   [0:0]                               flg_wfmode;
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    flg_flgptn;

    logic                                       timcnt_en;
    logic                                       timeout;
        
    er_t                                        er_code;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            rdq_add_req <= 1'b0;
            timeout_req <= 1'b0;
            tskstat_wai <= 1'b1;
            tskstat_sus <= 1'b0;
            tskwait_slp <= 1'b1;
            tskwait_dly <= 1'b0;
            tskwait_sem <= 1'b0;
            tskwait_flg <= 1'b0;
            tskpri      <= TSKPRI_WIDTH'(TSKID);
            wupcnt      <= '0;
            suscnt      <= '0;
            timcnt      <= '0;
            timcnt_en   <= 1'b0;
            timeout     <= 1'b0;
            er_code     <= E_OK;
        end
        else if ( cke ) begin
            // chg_pri
            if ( chg_pri ) begin
                // 動作中の優先度変更はホストCPU側でキューの取り外し＆取付けをやり直す事
                tskpri <= chg_pri_tskpri;
            end

            // wup_tsk
            if ( wup_tsk ) begin
                if ( tskwait_slp ) begin
                    // wake-up
                    tskstat_wai <= 1'b0;
                    tskwait_slp <= 1'b0;
                    rdq_add_req <= !tskstat_sus;
                    er_code     <= E_OK;
                end
                else begin
                    // nest
                    if ( wupcnt != TMAX_WUPCNT ) begin
                        wupcnt <= wupcnt + 1'b1;
                        er_code <= E_OK;
                    end
                    else begin
                        er_code <= E_QOVR;
                    end
                end
            end

            // slp_tsk
            if ( slp_tsk ) begin
                if ( !tskwait_slp ) begin
                    if ( wupcnt != '0 ) begin
                        wupcnt <= wupcnt - 1'b1;
                        er_code     <= E_OK;
                    end
                    else begin
                        // sleep
                        tskstat_wai <= 1'b1;
                        tskwait_slp <= 1'b1;
                        er_code <= E_OK;
                    end
                end
                else begin
                    er_code <= E_OBJ;
                end
            end

            // sus_tsk
            if ( sus_tsk ) begin
                if ( tskstat_sus ) begin
                    if ( suscnt != TMAX_SUSCNT) begin
                        suscnt <= suscnt + 1'b1;
                        er_code <= E_OK;
                    end
                    else begin
                        er_code <= E_QOVR;
                    end
                end
                else begin
                    // suspend
                    tskstat_sus <= 1'b1;
                end
            end

            // rsm_tsk
            if ( rsm_tsk ) begin
                if ( tskstat_sus ) begin
                    if ( suscnt != '0 ) begin
                        suscnt <= suscnt - 1'b1;
                    end
                    else begin
                        // resume
                        tskstat_sus <= 1'b0;
                        rdq_add_req <= !tskstat_wai;
                    end
                end
                else begin
                    er_code <= E_OBJ;
                end
            end

            // dly_tsk
            if ( dly_tsk ) begin
                timcnt      <= dly_tsk_dlytim;
                timcnt_en   <= 1'b1;
                tskstat_wai <= 1'b1;
                tskwait_dly <= 1'b1;
            end


            // rel_wai
            if ( rel_wai ) begin
                tskstat_wai <= 1'b0;
                tskwait_slp <= 1'b0;
                tskwait_dly <= 1'b0;
                tskwait_sem <= 1'b0;
                tskwait_flg <= 1'b0;
                timcnt_en   <= 1'b0;
                timcnt      <= 'x;
                rdq_add_req <= !tskstat_sus;            
                er_code <= E_RLWAI;
            end

            // wai_sem
            if ( wai_sem ) begin
                tskstat_wai <= 1'b1;
                tskwait_sem <= 1'b1;
            end


            // wake-up from event-flag
            if ( tskwait_flg ) begin
                if ( (flg_wfmode == 1'b0 && ((flgptn | ~flg_flgptn) == '1))
                     || (flg_wfmode == 1'b1 && ((flgptn &  flg_flgptn) != '0)) ) begin
                    tskwait_flg <= 1'b0;
                    tskstat_wai <= 1'b0;
                    rdq_add_req <= !tskstat_sus;
                end
            end

            // wai_flg
            if ( wai_flg ) begin
                flg_wfmode  <= wai_flg_wfmode;
                flg_flgptn  <= wai_flg_flgptn;
                tskstat_wai <= 1'b1;
                tskwait_flg <= 1'b1;
            end


            // set_tmo
            if ( set_tmo && tskstat_wai ) begin
                timcnt      <= set_tmo_tmotim;
                timcnt_en   <= 1'b1;
                tskstat_wai <= 1'b1;
            end

            // timer count
            timeout <= 1'b0;
            if ( timcnt_en ) begin
                timcnt <= timcnt - RELTIM_WIDTH'(time_tick);
                if ( (timcnt - RELTIM_WIDTH'(time_tick)) == '0 ) begin
                    timcnt_en <= 1'b0;
                    timeout   <= 1'b1;
                end
            end

            // timeout
            if ( timeout ) begin
                if ( tskwait_sem ) begin
                    timeout_req <= 1'b1;
                end
                else begin
                    tskstat_wai <= 1'b0;
                    tskwait_slp <= 1'b0;
                    tskwait_dly <= 1'b0;
                    tskwait_sem <= 1'b0;
                    tskwait_flg <= 1'b0;
                    rdq_add_req <= !tskstat_sus;                    
                    er_code <= E_TMOUT;
                end 
            end

            if ( timeout_ack ) begin
                tskstat_wai <= 1'b0;
                tskwait_slp <= 1'b0;
                tskwait_dly <= 1'b0;
                tskwait_sem <= 1'b0;
                tskwait_flg <= 1'b0;
                rdq_add_req <= !tskstat_sus;
                er_code <= E_TMOUT;
            end


            // release task from wait object
            if ( rel_tsk ) begin
                tskstat_wai <= 1'b0;
                tskwait_sem <= 1'b0;
                rdq_add_req <= !tskstat_sus;
                er_code <= E_OK;
            end

            // add_rdq complete
            if ( rdq_add_ack ) begin
                rdq_add_req <= 1'b0;
            end

            if ( !USE_ER ) begin
                er_code <= E_OK;
            end
        end
    end

    always_comb begin : blk_rdq_rmv
        rdq_rmv  = 1'b0;
        case ( 1'b1 )
        slp_tsk:  begin   rdq_rmv = (wupcnt == '0); end
        sus_tsk:  begin   rdq_rmv = 1'b1;   end
        dly_tsk:  begin   rdq_rmv = 1'b1;   end
        wai_sem:  begin   rdq_rmv = 1'b1;   end
        wai_flg:  begin   rdq_rmv = 1'b1;   end
        endcase
    end

    always_comb begin
        tskstat_run = run_valid;
        tskstat_rdy = !run_valid && !tskstat_wai && !tskstat_sus;
        tskstat = TTS_WIDTH'({
                        tskstat_sus,
                        tskstat_wai,
                        tskstat_rdy,
                        tskstat_run});
    end

    always_comb begin
        tskwait = TTW_WIDTH'({
                        tskwait_flg,
                        tskwait_sem,
                        tskwait_slp,
                        tskwait_dly});
    end

    assign er      = er_code;
    assign busy    = rdq_add_req || timeout_req;

endmodule


`default_nettype wire


// End of file
