// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// Dualport-RAM
module test_rom
        (
            input   wire                clk,
            input   wire                en,
            input   wire    [11:0]      addr,
            output  reg     [31:0]      dout
        );
    

    (* ram_style = "block" *)
    logic   [31:0]   mem [0:4095];
    
    initial begin
        for ( int i = 0; i < 4096; ++i ) begin
            mem[i] = 2**(i%16) + i**2 / 7 + i/11 + (i**3)%77147 + i*7/3 + i;
        end
    end
    
    always_ff @(posedge clk) begin
        if ( en ) begin
            dout <= mem[addr];
        end
    end

endmodule


`default_nettype wire


// End of file
