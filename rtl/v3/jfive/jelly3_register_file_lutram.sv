// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly3_register_file_lutram
        #(
            parameter   int     READ_PORTS  = 2                     ,
            parameter   int     ADDR_BITS   = 5                     ,
            parameter   type    addt_t      = logic [ADDR_BITS-1:0] ,
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
            input   var addt_t                      wr_addr,
            input   var data_t                      wr_din,

            // read port
            input   var logic   [READ_PORTS-1:0]    rd_en,
            input   var addt_t  [READ_PORTS-1:0]    rd_addr,
            output  var data_t  [READ_PORTS-1:0]    rd_dout
        );
    
    generate
    for ( genvar i = 0; i < READ_PORTS; ++i ) begin
        logic   overwrite;
        always_comb begin
            overwrite = 1'b0;
            if ( wr_en && (wr_addr == rd_addr[i]) ) begin
                overwrite = 1'b1;
            end
        end

        data_t  rdout;
        jelly2_ram_async_dualport
                #(
                    .ADDR_WIDTH     ($bits(addt_t)  ),
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
                    .port1_dout     (rdout          )
                );
            
        always_ff @(posedge clk) begin
            if ( rd_en[i] ) begin
                if ( wr_en && (wr_addr == rd_addr[i]) ) begin
                    rd_dout[i] <= wr_din;
                end
                else begin
                    rd_dout[i] <= rdout;
                    if ( ZERO_REG && (rd_addr[i] == 0) ) begin
                        rd_dout[i] <= '0;
                    end
                end
            end
        end
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
