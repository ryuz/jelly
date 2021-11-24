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

            output  reg                         busy,

            output  reg     [TSKPRI_WIDTH-1:0]  tskpri,
            output  wire    [2:0]               tskstat,

            output  reg                         req_rdq,
            input   wire                        rdy_tsk,
            input   wire                        rel_tsk,
            input   wire    [FLGPTN_WIDTH-1:0]  flgptn,
            
            input   wire    [TSKID_WIDTH-1:0]   op_tskid,
            input   wire                        wup_tsk_valid,
            input   wire                        slp_tsk_valid,
            input   wire    [RELTIM_WIDTH-1:0]  dly_tsk_dlytim,
            input   wire                        dly_tsk_valid,
            input   wire                        rel_wai_valid,
            input   wire                        wai_sem_valid,
            input   wire    [0:0]               wai_flg_wfmode,
            input   wire    [FLGPTN_WIDTH-1:0]  wai_flg_flgptn,
            input   wire                        wai_flg_valid
        );

    typedef enum bit [2:0] {
        TS_SLEEP  = 3'h0,
        TS_REQRDY = 3'h1,
        TS_READY  = 3'h2,
        TS_DELAY  = 3'h3,
        TS_WAISEM = 3'h4,
        TS_WAIFLG = 3'h5
    } tskstat_t;

    tskstat_t                   cur_tskstat  = TS_SLEEP;
    tskstat_t                   next_tskstat = TS_SLEEP;

    logic   [0:0]               flg_wfmode;
    logic   [FLGPTN_WIDTH-1:0]  flg_flgptn;

    logic   [RELTIM_WIDTH-1:0]  dlytim;

    always_comb begin : blk_next_stat
        next_tskstat = cur_tskstat;

        if ( cur_tskstat == TS_WAIFLG ) begin
            if ( (flg_wfmode == 1'b0 && ((flgptn | ~flg_flgptn) == '1))
              || (flg_wfmode == 1'b1 && ((flgptn &  flg_flgptn) != '0)) ) begin
                next_tskstat = TS_REQRDY;
            end
        end

        if ( cur_tskstat == TS_DELAY ) begin
            if ( dlytim == '0 ) begin
                next_tskstat = TS_REQRDY;
            end
        end
        
        if ( op_tskid == TSKID ) begin
            case ( 1'b1 )
            wup_tsk_valid:    begin   next_tskstat = TS_REQRDY;   end
            slp_tsk_valid:    begin   next_tskstat = TS_SLEEP;    end
            dly_tsk_valid:    begin   next_tskstat = TS_DELAY;    end
            rel_wai_valid:    begin   next_tskstat = TS_REQRDY;   end
            wai_sem_valid:    begin   next_tskstat = TS_WAISEM;   end
            wai_flg_valid:    begin   next_tskstat = TS_WAIFLG;   end
            endcase
        end

        if ( rel_tsk ) begin
            next_tskstat = TS_REQRDY;
        end

        if ( rdy_tsk ) begin
            next_tskstat = TS_READY;
        end
    end


    always_ff @(posedge clk) begin
        if ( reset ) begin
            cur_tskstat <= TS_SLEEP;
            req_rdq     <= 1'b0;
            
            tskpri      <=INIT_TSKPRI;

            flg_wfmode  <= 'x;
            flg_flgptn  <= 'x;
        end
        else if ( cke ) begin
            cur_tskstat <= next_tskstat;
            req_rdq     <= (next_tskstat == TS_REQRDY);

            if ( wai_flg_valid ) begin
                flg_wfmode <= wai_flg_wfmode;
                flg_flgptn <= wai_flg_flgptn;
            end

            if ( dlytim > '0 ) begin
                dlytim <= dlytim - 1'b1;
            end
            if ( dly_tsk_valid ) begin
                dlytim <= dly_tsk_dlytim;
            end
        end
    end

    assign busy    = (next_tskstat == TS_REQRDY);
    assign tskstat = cur_tskstat;

endmodule


`default_nettype wire


// End of file
