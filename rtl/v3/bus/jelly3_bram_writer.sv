// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_bram_writer
        #(
            parameter   int     LATENCY     = 1                     ,
            parameter   int     ADDR_BITS   = 10                    ,
            parameter   type    addr_t      = logic [ADDR_BITS-1:0] ,
            parameter   int     DATA_BITS   = 32                    ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   int     BYTE_BITS   = 8                     ,
            parameter   int     WE_BITS     = DATA_BITS / BYTE_BITS ,
            parameter   type    we_t        = logic [WE_BITS-1:0]   
        )
        (
            jelly3_bram_if.sw   bram    ,

            output  var logic   en      ,
            output  var we_t    we      ,
            output  var addr_t  addr    ,
            output  var data_t  wdata   
        );

    assign bram.cready = 1'b1;

    assign en    = bram.cwrite          ;
    assign we    = bram.cstrb           ;
    assign addr  = addr_t'(bram.caddr)  ;
    assign wdata = bram.cdata           ;

endmodule


`default_nettype wire


// end of file
