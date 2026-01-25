// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly3_jfive_register_file
        #(
            parameter   int     READ_PORTS  = 2                     ,
            parameter   int     ADDR_BITS   = 5                     ,
            parameter   type    addr_t      = logic [ADDR_BITS-1:0] ,
            parameter   int     DATA_BITS   = 32                    ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   int     REGISTERS   = (1 << ADDR_BITS)      , 
            parameter   bit     ZERO_REG    = 1'b0                  ,
            parameter           RAM_TYPE    = "distributed"         ,
            parameter           DEVICE      = "RTL"                 ,
            parameter           SIMULATION  = "false"               ,
            parameter           DEBUG       = "false"               
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,

            // write port
            input   var logic                       wr_en,
            input   var addr_t                      wr_addr,
            input   var data_t                      wr_din,

            // read port
            input   var addr_t  [READ_PORTS-1:0]    rd_addr,
            output  var data_t  [READ_PORTS-1:0]    rd_dout
        );
    
    generate
    for ( genvar i = 0; i < READ_PORTS; ++i ) begin
        jelly2_ram_async_dualport
                #(
                    .ADDR_WIDTH     ($bits(addr_t)  ),
                    .DATA_WIDTH     ($bits(data_t)  ),
                    .RAM_TYPE       (RAM_TYPE       ),
                    .MEM_SIZE       (REGISTERS      ),
                    .FILLMEM        (1'b1           ),
                    .FILLMEM_DATA   ('0             )
                )
            u_ram_async_dualport
                (
                    .port0_clk      (clk            ),
                    .port0_we       (cke & wr_en    ),
                    .port0_addr     (wr_addr        ),
                    .port0_din      (wr_din         ),
                    .port0_dout     (               ),

                    .port1_addr     (rd_addr[i]     ),
                    .port1_dout     (rd_dout[i]     )
                );
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
