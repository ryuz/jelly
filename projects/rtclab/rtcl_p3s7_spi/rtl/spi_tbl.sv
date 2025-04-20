

`timescale 1ns / 1ps
`default_nettype none

module spi_tbl
        (
            input  var logic   [7:0]   addr,
            output  var logic  [27:0]  dout
        );

    always_comb begin
        case ( addr )
        8'h00:   dout = {2'b01, 26'd1000};
        8'h01:   dout = {2'b00, 9'd000, 1'b0, 16'h0000};    // READ chip_id
        8'h02:   dout = {2'b00, 9'd001, 1'b0, 16'h0000};    // READ resolution
        8'h03:   dout = {2'b00, 9'd002, 1'b0, 16'h0000};    // READ chip_configuration

        8'h04:   dout = {2'b00, 9'd008, 1'b0, 16'h0000};    // READ  soft_reset_pll
        8'h05:   dout = {2'b00, 9'd008, 1'b1, 16'h0000};    // WRITE soft_reset_pll
        8'h06:   dout = {2'b00, 9'd008, 1'b0, 16'h0000};    // READ  soft_reset_pll

        default: dout = {2'b10, 9'h000, 1'b0, 16'h0000};    // end
        endcase
    end

endmodule

`default_nettype wire

// end of file
