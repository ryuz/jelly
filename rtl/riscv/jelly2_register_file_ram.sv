

// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// RAM実装のレジスタファイル(書き込みポートは1個のみ)
module jelly_register_file_ram
        #(
            parameter   int     READ_PORTS = 2,
            parameter   int     ADDR_WIDTH = 5,
            parameter   int     DATA_WIDTH = 32,
            parameter   int     REGISTERS  = (1 << ADDR_WIDTH),
            parameter           RAM_TYPE   = "distributed"
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            // write port
            input   wire                                        wr_en,
            input   wire    [ADDR_WIDTH-1:0]                    wr_addr,
            input   wire    [DATA_WIDTH-1:0]                    wr_din,

            // read port
            input   wire    [READ_PORTS-1:0]                    rd_en,
            input   wire    [READ_PORTS-1:0][ADDR_WIDTH-1:0]    rd_addr,
            output  wire    [READ_PORTS-1:0][DATA_WIDTH-1:0]    rd_dout
        );

    generate
    for ( genvar i = 0; i < READ_PORTS; ++i ) begin : loop_ram
        jelly2_ram_dualport
                #(
                    .ADDR_WIDTH         (ADDR_WIDTH),
                    .DATA_WIDTH         (DATA_WIDTH),
                    .MEM_SIZE           (REGISTERS),
                    .RAM_TYPE           ("block"),
                    .DOUT_REGS0         (0),
                    .DOUT_REGS1         (0),
                    .MODE0              ("WRITE_FIRST"),
                    .MODE1              ("WRITE_FIRST"),
                    .FILLMEM            (0),
                    .FILLMEM_DATA       (0)
                )
            i_ram_dualport
                (
                    .port0_clk          (clk),
                    .port0_en           (cke),
                    .port0_regcke       (cke),
                    .port0_we           (wr_en),
                    .port0_addr         (wr_addr),
                    .port0_din          (wr_din),
                    .port0_dout         (),
                    
                    .port1_clk          (clk),
                    .port1_en           (cke & rd_en[i]),
                    .port1_regcke       (cke),
                    .port1_we           (1'b0),
                    .port1_addr         (rd_addr[i]),
                    .port1_din          ('0),
                    .port1_dout         (rd_dout[i])
                );
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// End of file
