// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly2_register_file
        #(
            parameter   int     WRITE_PORTS = 1,
            parameter   int     READ_PORTS  = 2,
            parameter   int     ADDR_WIDTH  = 5,
            parameter   int     DATA_WIDTH  = 32,
            parameter   bit     ZERO_REG    = 0,
            parameter   int     REGISTERS   = (1 << ADDR_WIDTH),
            parameter           RAM_TYPE    = "distributed",
            parameter           DEVICE      = "RTL",
            parameter   bit     SIMULATION  = 1'b0
        )
        (
            input   var logic                                       reset,
            input   var logic                                       clk,
            input   var logic                                       cke,

            // write port
            input   var logic   [WRITE_PORTS-1:0]                   wr_en,
            input   var logic   [WRITE_PORTS-1:0][ADDR_WIDTH-1:0]   wr_addr,
            input   var logic   [WRITE_PORTS-1:0][DATA_WIDTH-1:0]   wr_din,

            // read port
            input   var logic   [READ_PORTS-1:0]                    rd_en,
            input   var logic   [READ_PORTS-1:0][ADDR_WIDTH-1:0]    rd_addr,
            output  var logic   [READ_PORTS-1:0][DATA_WIDTH-1:0]    rd_dout
        );

    generate
    if ( WRITE_PORTS == 1 && ADDR_WIDTH == 5 && 256'(RAM_TYPE) == 256'("distributed") ) begin : blk_ram32x1
        jelly2_register_file_ram32x1d
                #(
                    .READ_PORTS     (READ_PORTS),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .DEVICE         (DEVICE)
                )
            i_register_file_ram32x1d
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),

                    .wr_en          (wr_en),
                    .wr_addr        (wr_addr),
                    .wr_din         (wr_din),
                    
                    .rd_en          (rd_en),
                    .rd_addr        (rd_addr),
                    .rd_dout        (rd_dout)
                );
    end
    else if ( WRITE_PORTS == 1) begin : blk_ram
        jelly2_register_file_ram
                #(
                    .READ_PORTS     (READ_PORTS),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .REGISTERS      (REGISTERS),
                    .RAM_TYPE       (RAM_TYPE)
                )
            i_register_file_ram
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),

                    .wr_en          (wr_en),
                    .wr_addr        (wr_addr),
                    .wr_din         (wr_din),
                    
                    .rd_en          (rd_en),
                    .rd_addr        (rd_addr),
                    .rd_dout        (rd_dout)
                );
    end
    else begin : blk_ff
        jelly2_register_file_ff
                #(
                    .WRITE_PORTS    (WRITE_PORTS),
                    .READ_PORTS     (READ_PORTS),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .ZERO_REG       (ZERO_REG),
                    .REGISTERS      (REGISTERS)
                )
            i_register_file_ff
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),

                    .wr_en          (wr_en),
                    .wr_addr        (wr_addr),
                    .wr_din         (wr_din),
                    
                    .rd_en          (rd_en),
                    .rd_addr        (rd_addr),
                    .rd_dout        (rd_dout)
                );
    end
    endgenerate

    // モニタリング用変数
    generate
    if ( SIMULATION ) begin : blk_sim
        logic   [DATA_WIDTH-1:0]    x0  = 0;
        logic   [DATA_WIDTH-1:0]    x1  = 0;
        logic   [DATA_WIDTH-1:0]    x2  = 0;
        logic   [DATA_WIDTH-1:0]    x3  = 0;
        logic   [DATA_WIDTH-1:0]    x4  = 0;
        logic   [DATA_WIDTH-1:0]    x5  = 0;
        logic   [DATA_WIDTH-1:0]    x6  = 0;
        logic   [DATA_WIDTH-1:0]    x7  = 0;
        logic   [DATA_WIDTH-1:0]    x8  = 0;
        logic   [DATA_WIDTH-1:0]    x9  = 0;
        logic   [DATA_WIDTH-1:0]    x10 = 0;
        logic   [DATA_WIDTH-1:0]    x11 = 0;
        logic   [DATA_WIDTH-1:0]    x12 = 0;
        logic   [DATA_WIDTH-1:0]    x13 = 0;
        logic   [DATA_WIDTH-1:0]    x14 = 0;
        logic   [DATA_WIDTH-1:0]    x15 = 0;
        logic   [DATA_WIDTH-1:0]    x16 = 0;
        logic   [DATA_WIDTH-1:0]    x17 = 0;
        logic   [DATA_WIDTH-1:0]    x18 = 0;
        logic   [DATA_WIDTH-1:0]    x19 = 0;
        logic   [DATA_WIDTH-1:0]    x20 = 0;
        logic   [DATA_WIDTH-1:0]    x21 = 0;
        logic   [DATA_WIDTH-1:0]    x22 = 0;
        logic   [DATA_WIDTH-1:0]    x23 = 0;
        logic   [DATA_WIDTH-1:0]    x24 = 0;
        logic   [DATA_WIDTH-1:0]    x25 = 0;
        logic   [DATA_WIDTH-1:0]    x26 = 0;
        logic   [DATA_WIDTH-1:0]    x27 = 0;
        logic   [DATA_WIDTH-1:0]    x28 = 0;
        logic   [DATA_WIDTH-1:0]    x29 = 0;
        logic   [DATA_WIDTH-1:0]    x30 = 0;
        logic   [DATA_WIDTH-1:0]    x31 = 0;
        always_ff @(posedge clk) begin
            if ( wr_en ) begin
                case ( int'(wr_addr) )
                0:  x0  <= wr_din;
                1:  x1  <= wr_din;
                2:  x2  <= wr_din;
                3:  x3  <= wr_din;
                4:  x4  <= wr_din;
                5:  x5  <= wr_din;
                6:  x6  <= wr_din;
                7:  x7  <= wr_din;
                8:  x8  <= wr_din;
                9:  x9  <= wr_din;
                10: x10 <= wr_din;
                11: x11 <= wr_din;
                12: x12 <= wr_din;
                13: x13 <= wr_din;
                14: x14 <= wr_din;
                15: x15 <= wr_din;
                16: x16 <= wr_din;
                17: x17 <= wr_din;
                18: x18 <= wr_din;
                19: x19 <= wr_din;
                20: x20 <= wr_din;
                21: x21 <= wr_din;
                22: x22 <= wr_din;
                23: x23 <= wr_din;
                24: x24 <= wr_din;
                25: x25 <= wr_din;
                26: x26 <= wr_din;
                27: x27 <= wr_din;
                28: x28 <= wr_din;
                29: x29 <= wr_din;
                30: x30 <= wr_din;
                31: x31 <= wr_din;
                default: ;
                endcase
            end
        end
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
