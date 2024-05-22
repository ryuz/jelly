// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly3_register_file
        #(
            parameter   int     WRITE_PORTS = 1                     ,
            parameter   int     READ_PORTS  = 2                     ,
            parameter   int     ADDR_BITS   = 5                     ,
            parameter   type    addt_t      = logic [ADDR_BITS-1:0] ,
            parameter   int     DATA_BITS   = 32                    ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   bit     ZERO_REG    = 1'b0                  ,
            parameter   int     REGISTERS   = (1 << ADDR_BITS)      , 
            parameter           RAM_TYPE    = "distributed"         ,
            parameter           DEVICE      = "RTL"                 ,
            parameter           SIMULATION  = "false"               ,
            parameter           DEBUG       = "false"               
        )
        (
            input   var logic                       reset           ,
            input   var logic                       clk             ,
            input   var logic                       cke             ,

            // write port
            input   var logic   [WRITE_PORTS-1:0]   wr_en           ,
            input   var addt_t  [WRITE_PORTS-1:0]   wr_addr         ,
            input   var data_t  [WRITE_PORTS-1:0]   wr_din          ,

            // read port
            input   var logic   [READ_PORTS-1:0]    rd_en           ,
            input   var addt_t  [READ_PORTS-1:0]    rd_addr         ,
            output  var data_t  [READ_PORTS-1:0]    rd_dout
        );

    generate
    if ( WRITE_PORTS == 1 && string'(RAM_TYPE) == "distributed" ) begin : lutram
        jelly3_register_file_lutram
                #(
                    .READ_PORTS     (READ_PORTS ),
                    .ADDR_BITS      (ADDR_BITS  ),
                    .addt_t         (addt_t     ),
                    .DATA_BITS      (DATA_BITS  ),
                    .data_t         (data_t     ),
                    .REGISTERS      (REGISTERS  ),
                    .ZERO_REG       (ZERO_REG   ),
                    .RAM_TYPE       (RAM_TYPE   ),
                    .DEVICE         (DEVICE     ),
                    .SIMULATION     (SIMULATION ),
                    .DEBUG          (DEBUG      )
                )
            i_register_file_ram32x1d
                (
                    .reset          (reset      ),
                    .clk            (clk        ),
                    .cke            (cke        ),

                    .wr_en          (wr_en      ),
                    .wr_addr        (wr_addr    ),
                    .wr_din         (wr_din     ),
                    
                    .rd_en          (rd_en      ),
                    .rd_addr        (rd_addr    ),
                    .rd_dout        (rd_dout    )
                );
    end
    else if ( WRITE_PORTS == 1 ) begin : blk_ram
        jelly2_register_file_ram
                #(
                    .READ_PORTS     (READ_PORTS ),
                    .ADDR_WIDTH     (ADDR_BITS  ),
                    .DATA_WIDTH     (DATA_BITS  ),
                    .REGISTERS      (REGISTERS  ),
                    .RAM_TYPE       (RAM_TYPE   )
                )
            i_register_file_ram
                (
                    .reset          (reset      ),
                    .clk            (clk        ),
                    .cke            (cke        ),

                    .wr_en          (wr_en      ),
                    .wr_addr        (wr_addr    ),
                    .wr_din         (wr_din     ),
                    
                    .rd_en          (rd_en      ),
                    .rd_addr        (rd_addr    ),
                    .rd_dout        (rd_dout    )
                );
    end
    else begin : blk_ff
        jelly2_register_file_ff
                #(
                    .WRITE_PORTS    (WRITE_PORTS),
                    .READ_PORTS     (READ_PORTS ),
                    .ADDR_WIDTH     (ADDR_BITS  ),
                    .DATA_WIDTH     (DATA_BITS  ),
                    .ZERO_REG       (ZERO_REG   ),
                    .REGISTERS      (REGISTERS  )
                )
            i_register_file_ff
                (
                    .reset          (reset      ),
                    .clk            (clk        ),
                    .cke            (cke        ),

                    .wr_en          (wr_en      ),
                    .wr_addr        (wr_addr    ),
                    .wr_din         (wr_din     ),
                    
                    .rd_en          (rd_en      ),
                    .rd_addr        (rd_addr    ),
                    .rd_dout        (rd_dout    )
                );
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
