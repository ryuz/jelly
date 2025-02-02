// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_bram_accessor
        #(
            parameter   int     WLATENCY    = 1                         ,
            parameter   int     RLATENCY    = 2                         ,
            localparam  int     LATENCY     = RLATENCY                  ,
            parameter   type    en_t        = logic [LATENCY-1:0]       ,
            parameter   int     ADDR_BITS   = 10                        ,
            parameter   type    addr_t      = logic [ADDR_BITS-1:0]     ,
            parameter   int     DATA_BITS   = 32                        ,
            parameter   type    data_t      = logic [DATA_BITS-1:0]     ,
            parameter   int     BYTE_BITS   = 8                         ,
            parameter   int     WE_BITS     = DATA_BITS / BYTE_BITS     ,
            parameter   type    we_t        = logic [WE_BITS-1:0]       
        )
        (
            jelly3_bram_if.s    s_bram  ,

            output  var en_t    en      ,
            output  var we_t    we      ,
            output  var addr_t  addr    ,
            output  var data_t  wdata   ,
            input   var data_t  rdata   
        );

    localparam  type    id_t = logic [s_bram.ID_BITS-1:0];

    id_t    mem_id      [0:LATENCY-1];
    logic   mem_last    [0:LATENCY-1];
    logic   mem_valid   [0:LATENCY-1];
    always_ff @ ( posedge s_bram.clk ) begin
        for (int i = 0; i < LATENCY; i++ ) begin
            if ( s_bram.reset ) begin
                mem_id   [i] <= 'x;
                mem_last [i] <= 'x;
                mem_valid[i] <= '0;
            end
            else if ( s_bram.cready ) begin
                if ( i == 0 ) begin
                    mem_id   [i] <= s_bram.cid   ;
                    mem_last [i] <= s_bram.clast ;
                    mem_valid[i] <= s_bram.cread ;
                end
                else begin
                    mem_id   [i] <= mem_id   [i-1];
                    mem_last [i] <= mem_last [i-1];
                    mem_valid[i] <= mem_valid[i-1];
                end
            end
        end
    end

    assign en    = {LATENCY{s_bram.cke}}  ;
    assign we    = we_t'(s_bram.cstrb)    ;
    assign addr  = addr_t'(s_bram.caddr)  ;
    assign wdata = s_bram.cdata           ;

    assign s_bram.cready = !s_bram.rvalid || s_bram.rready;

    assign s_bram.rid    = mem_id   [LATENCY-1]   ;
    assign s_bram.rlast  = mem_last [LATENCY-1]   ;
    assign s_bram.rdata  = rdata                  ;
    assign s_bram.rvalid = mem_valid[LATENCY-1]   ;

endmodule


`default_nettype wire


// end of file
