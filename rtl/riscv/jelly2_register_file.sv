// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly_register_file
        #(
            parameter   int     WRITE_PORTS = 1,
            parameter   int     READ_PORTS  = 2,
            parameter   int     ADDR_WIDTH  = 5,
            parameter   int     DATA_WIDTH  = 32,
            parameter   bit     ZERO_REG    = 0,
            parameter   int     REGISTERS   = (1 << ADDR_WIDTH)
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            // write port
            input   wire    [WRITE_PORTS-1:0]                   wr_en,
            input   wire    [WRITE_PORTS-1:0][ADDR_WIDTH-1:0]   wr_addr,
            input   wire    [WRITE_PORTS-1:0][DATA_WIDTH-1:0]   wr_din,

            // read port
            input   wire    [READ_PORTS-1:0]                    rd_en,
            input   wire    [READ_PORTS-1:0][ADDR_WIDTH-1:0]    rd_addr,
            output  reg     [READ_PORTS-1:0][DATA_WIDTH-1:0]    rd_dout
        );

    logic   [REGISTERS-1:0][DATA_WIDTH-1:0]  reg_files;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_files <= '0;
            rd_dout   <= '0;
        end
        else if ( cke ) begin
            automatic logic [REGISTERS-1:0][DATA_WIDTH-1:0] tmp_files;
            tmp_files = reg_files;

            for ( int i = 0; i < WRITE_PORTS; ++i ) begin
                if ( wr_en[i] ) begin
                    tmp_files[wr_addr[i]] = wr_din[i];
                end
            end

            for ( int i = 0; i < READ_PORTS; ++i ) begin
                if ( rd_en[i] ) begin
                    rd_dout[i] <= tmp_files[rd_addr[i]];
                end
            end

            if ( ZERO_REG ) begin
                tmp_files[0] = '0;
            end

            reg_files <= tmp_files;
        end
    end

endmodule


`default_nettype wire


// End of file
