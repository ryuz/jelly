


`timescale 1ns / 1ps
`default_nettype none


module draw_video
        #(
            parameter X_WIDTH = 10,
            parameter Y_WIDTH = 10
        )
        (
            input   var logic                   reset,
            input   var logic                   clk,

            // input        
            input   var logic                   in_vsync,
            input   var logic                   in_hsync,
            input   var logic                   in_de,
            input   var logic   [X_WIDTH-1:0]   in_x,
            input   var logic   [Y_WIDTH-1:0]   in_y,
            
            // output
            output  var logic                   out_vsync,
            output  var logic                   out_hsync,
            output  var logic                   out_de,
            output  var logic   [2:0][7:0]      out_rgb
        );
    
        logic                           st0_vsync;
        logic                           st0_hsync;
        logic                           st0_de   ;
        logic   signed  [X_WIDTH:0]     st0_x    ;
        logic   signed  [Y_WIDTH:0]     st0_y    ;

        logic                           st1_vsync;
        logic                           st1_hsync;
        logic                           st1_de   ;
        logic           [X_WIDTH*2:0]   st1_xx   ;
        logic           [Y_WIDTH*2:0]   st1_yy   ;

        logic                           st2_vsync;
        logic                           st2_hsync;
        logic                           st2_de   ;
        logic   [X_WIDTH*2+Y_WIDTH*2:0] st2_len  ;
        
        always_ff @(posedge clk) begin
            st0_vsync <= in_vsync;
            st0_hsync <= in_hsync;
            st0_de    <= in_de;
            st0_x     <= $signed(in_x) - 360;
            st0_y     <= $signed(in_y) - 240;

            st1_vsync <= st0_vsync;
            st1_hsync <= st0_hsync;
            st1_de    <= st0_de;
            st1_xx    <= st0_x * st0_x;
            st1_yy    <= st0_y * st0_y;

            st2_vsync <= st0_vsync;
            st2_hsync <= st0_hsync;
            st2_de    <= st0_de;
            st2_len   <= st1_xx + st1_yy;

            out_vsync  <= st2_vsync;
            out_hsync  <= st2_hsync;
            out_de     <= st2_de;
            out_rgb[2] <= st2_len < 100*100 ? 8'hff : 8'h00;
            out_rgb[1] <= st2_len < 150*150 ? 8'hff : 8'h00;
            out_rgb[0] <= st2_len < 200*200 ? 8'hff : 8'h00;
        end
    

endmodule


`default_nettype wire


// end of file
