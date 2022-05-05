
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_ram32x1d
        #(
            parameter   INIT             = 32'd0,
            parameter   IS_WCLK_INVERTED = 1'b0,
            parameter   DEVICE           = "RTL"
        )
        (
            input   wire                wclk,
            input   wire                wen,
            input   wire    [4:0]       waddr,
            input   wire                wdin,
            output  reg                 wdout,
            
            input   wire    [4:0]       raddr,
            output  reg                 rdout
        );

`ifdef VERILATOR
    localparam  SIM = 1'b1;
`else
    localparam  SIM = 1'b0;
`endif

    generate
    if ( !SIM && (
            256'(DEVICE) == 256'("SPARTAN6") ||
            256'(DEVICE) == 256'("VIRTEX6") ||
            256'(DEVICE) == 256'("7SERIES") ||
            256'(DEVICE) == 256'("ULTRASCALE") ||
            256'(DEVICE) == 256'("ULTRASCALE_PLUS") ||
            256'(DEVICE) == 256'("ULTRASCALE_PLUS_ES1") ||
            256'(DEVICE) == 256'("ULTRASCALE_PLUS_ES2")) ) begin : xilinx_ram32x1d
        // xilinx
        RAM32X1D
                #(
                    .INIT               (INIT),
                    .IS_WCLK_INVERTED   (IS_WCLK_INVERTED)
                )
            i_ram32x1d
                (
                    .WCLK               (wclk),
                    .WE                 (wen),
                    .A0                 (waddr[0]),
                    .A1                 (waddr[1]),
                    .A2                 (waddr[2]),
                    .A3                 (waddr[3]),
                    .A4                 (waddr[4]),
                    .D                  (wdin),
                    .SPO                (wdout),

                    .DPRA0              (raddr[0]),
                    .DPRA1              (raddr[1]),
                    .DPRA2              (raddr[2]),
                    .DPRA3              (raddr[3]),
                    .DPRA4              (raddr[4]),
                    .DPO                (rdout)
                );
    end
    else begin
        logic   [31:0]  mem = INIT;
        logic           clock;
        assign clock = IS_WCLK_INVERTED ? ~wclk : wclk;

        always_ff @(posedge clock) begin
            if ( wen ) begin
                mem[waddr] <= wdin;
            end
        end

        always_comb begin
            wdout = mem[waddr];
        end

        always_comb begin
            rdout = mem[raddr];
        end
    end
    endgenerate

endmodule

`default_nettype wire

// end of file
