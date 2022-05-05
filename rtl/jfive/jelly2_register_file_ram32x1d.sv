// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly2_register_file_ram32x1d
        #(
            parameter   int     READ_PORTS  = 2,
            parameter   int     DATA_WIDTH  = 32,
            parameter           DEVICE      = "RTL"
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            // write port
            input   wire                                        wr_en,
            input   wire    [4:0]                               wr_addr,
            input   wire    [DATA_WIDTH-1:0]                    wr_din,

            // read port
            input   wire    [READ_PORTS-1:0]                    rd_en,
            input   wire    [READ_PORTS-1:0][4:0]               rd_addr,
            output  reg     [READ_PORTS-1:0][DATA_WIDTH-1:0]    rd_dout
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

        for ( genvar j = 0; j < DATA_WIDTH; ++j ) begin
            wire        rdout;
            jelly2_ram32x1d
                    #(
                        .INIT               (32'd0),
                        .IS_WCLK_INVERTED   (1'b0),
                        .DEVICE             (DEVICE)
                    )
                i_ram32x1d
                    (
                        .wclk               (clk),
                        .wen                (cke & wr_en),
                        .waddr              (wr_addr),
                        .wdin               (wr_din[j]),
                        .wdout              (),

                        .raddr              (rd_addr[i]),
                        .rdout              (rdout)
                    );
            
            always_ff @(posedge clk) begin
                if ( rd_en[i] ) begin
                    rd_dout[i][j] <= overwrite ? wr_din[j] : rdout;
                end
            end
        end
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
