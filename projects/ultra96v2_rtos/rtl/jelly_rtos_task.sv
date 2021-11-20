// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_task
        #(
            parameter   int                         TSKID_WIDTH  = 4,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMID_WIDTH  = 4,
            parameter   int                         FLGPTN_WIDTH = 4,
            parameter   int                         RELTIM_WIDTH = 32,
            parameter   bit     [TSKID_WIDTH-1:0]   TSKID        = 0,
            parameter   bit     [TSKPRI_WIDTH-1:0]  INIT_TSKPRI  = TSKPRI_WIDTH'(TSKID)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            output  reg     [TSKPRI_WIDTH-1:0]  tskpri,
            output  reg     [3:0]               tskstat,

            output  reg                         req_rdq,

            input   wire                        rel_tsk,

            input   wire                        rdy_tsk,
            input   wire                        wup_tsk,
            input   wire                        slp_tsk,
            input   wire                        rel_wai,

            input   wire                        dly_tsk,
            input   wire    [RELTIM_WIDTH-1:0]  dly_tsk_dlytim,

            input   wire                        wai_sem,

            input   wire    [FLGPTN_WIDTH-1:0]  evtflg_flgptn,
            input   wire    [0:0]               wai_flg_wfmode,
            input   wire    [FLGPTN_WIDTH-1:0]  wai_flg_flgptn,
            input   wire                        wai_flg
        );

    typedef enum bit [3:0] {
        TS_SLEEP  = 4'h0,
        TS_REQRDY = 4'h1,
        TS_READY  = 4'h2,
        TS_DELAY  = 4'h3,
        TS_WAISEM = 4'h4,
        TS_WAIFLG = 4'h5
    } tskstat_t;

    tskstat_t                   reg_tskstat, next_tskstat;
    logic                       nop_tsk;

    logic   [0:0]               flg_wfmode;
    logic   [FLGPTN_WIDTH-1:0]  flg_flgptn;

    logic   [RELTIM_WIDTH-1:0]  dlytim;

    always_comb begin : blk_status
        next_tskstat = reg_tskstat;

        if ( reg_tskstat == TS_WAIFLG ) begin
            if ( (flg_wfmode == 1'b0 && ((evtflg_flgptn | ~flg_flgptn) == '1))
              || (flg_wfmode == 1'b1 && ((evtflg_flgptn &  flg_flgptn) != '0)) ) begin
                    next_tskstat = TS_REQRDY;
            end
        end

        if ( reg_tskstat == TS_DELAY ) begin
            if ( dlytim == '0 ) begin
                next_tskstat = TS_REQRDY;
            end
        end
        
        nop_tsk = !rdy_tsk && !wup_tsk && !slp_tsk && !rel_wai && !wai_flg;
        unique case ( 1'b1 )
        rdy_tsk:    begin   next_tskstat = TS_READY;    end
        rel_tsk:    begin   next_tskstat = TS_REQRDY;   end
        wup_tsk:    begin   next_tskstat = TS_REQRDY;   end
        slp_tsk:    begin   next_tskstat = TS_SLEEP;    end
        rel_wai:    begin   next_tskstat = TS_REQRDY;   end
        dly_tsk:    begin   next_tskstat = TS_DELAY;    end
        wai_sem:    begin   next_tskstat = TS_WAISEM;   end
        wai_flg:    begin   next_tskstat = TS_WAIFLG;   end
        nop_tsk: ;
        endcase
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_tskstat <= TS_SLEEP;
            req_rdq     <= 1'b0;
            
            tskpri      <=INIT_TSKPRI;

            flg_wfmode  <= 'x;
            flg_flgptn  <= 'x;
        end
        else if ( cke ) begin
            reg_tskstat <= next_tskstat;
            req_rdq     <= (next_tskstat == TS_REQRDY);

            if ( wai_flg ) begin
                flg_wfmode <= wai_flg_wfmode;
                flg_flgptn <= wai_flg_flgptn;
            end

            if ( dlytim > '0 ) begin
                dlytim <= dlytim - 1'b1;
            end
            if ( dly_tsk ) begin
                dlytim <= dly_tsk_dlytim;
            end
        end
    end

    assign tskstat = reg_tskstat;

endmodule


`default_nettype wire


// End of file
