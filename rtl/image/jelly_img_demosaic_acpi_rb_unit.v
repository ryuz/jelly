// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_demosaic_acpi_rb_unit
        #(
            parameter   DATA_WIDTH = 10
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire    [1:0]                   param_phase,
            
            input   wire                            in_line_first,
            input   wire                            in_pixel_first,
            input   wire    [3*3*2*DATA_WIDTH-1:0]  in_data,
            
            output  wire    [DATA_WIDTH-1:0]        out_raw,
            output  wire    [DATA_WIDTH-1:0]        out_r,
            output  wire    [DATA_WIDTH-1:0]        out_g,
            output  wire    [DATA_WIDTH-1:0]        out_b
        );
    
    
    // ŒvŽZ—p‚É—]—T‚ðŽ‚Á‚½•‚ð’è‹`
    localparam      CALC_WIDTH = DATA_WIDTH + 5;
    
    
    function signed [CALC_WIDTH+1:0]    absdiff(input signed [CALC_WIDTH-1:0] a, input signed [CALC_WIDTH-1:0] b);
    begin
        absdiff = a > b ? a - b : b - a;
    end
    endfunction
    
    function signed [CALC_WIDTH+1:0]    abs(input signed [CALC_WIDTH-1:0] a);
    begin
        abs = a >= 0 ? a : -a;
    end
    endfunction
    
    
    wire    signed  [CALC_WIDTH-1:0]    in_raw11 = in_data[((0*3+0)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw12 = in_data[((0*3+1)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw13 = in_data[((0*3+2)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw21 = in_data[((1*3+0)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw22 = in_data[((1*3+1)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw23 = in_data[((1*3+2)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw31 = in_data[((2*3+0)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw32 = in_data[((2*3+1)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_raw33 = in_data[((2*3+2)*2+0)*DATA_WIDTH +: DATA_WIDTH];
    
    wire    signed  [CALC_WIDTH-1:0]    in_g11   = in_data[((0*3+0)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g12   = in_data[((0*3+1)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g13   = in_data[((0*3+2)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g21   = in_data[((1*3+0)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g22   = in_data[((1*3+1)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g23   = in_data[((1*3+2)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g31   = in_data[((2*3+0)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g32   = in_data[((2*3+1)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    wire    signed  [CALC_WIDTH-1:0]    in_g33   = in_data[((2*3+2)*2+1)*DATA_WIDTH +: DATA_WIDTH];
    
    reg             [1:0]               reg_param_phase;
    
    reg             [1:0]               st0_phase;
    reg     signed  [CALC_WIDTH-1:0]    st0_raw;
    reg     signed  [CALC_WIDTH-1:0]    st0_g;
    reg     signed  [CALC_WIDTH-1:0]    st0_a0;
    reg     signed  [CALC_WIDTH-1:0]    st0_a1;
    reg     signed  [CALC_WIDTH-1:0]    st0_b0;
    reg     signed  [CALC_WIDTH-1:0]    st0_b1;
    reg     signed  [CALC_WIDTH-1:0]    st0_r;
    reg     signed  [CALC_WIDTH-1:0]    st0_l;
    reg     signed  [CALC_WIDTH-1:0]    st0_v0;
    reg     signed  [CALC_WIDTH-1:0]    st0_v1;
    reg     signed  [CALC_WIDTH-1:0]    st0_h0;
    reg     signed  [CALC_WIDTH-1:0]    st0_h1;
    
    reg             [1:0]               st1_phase;
    reg     signed  [CALC_WIDTH-1:0]    st1_raw;
    reg     signed  [CALC_WIDTH-1:0]    st1_g;
    reg     signed  [CALC_WIDTH-1:0]    st1_a0;
    reg     signed  [CALC_WIDTH-1:0]    st1_a1;
    reg     signed  [CALC_WIDTH-1:0]    st1_b0;
    reg     signed  [CALC_WIDTH-1:0]    st1_b1;
    reg     signed  [CALC_WIDTH-1:0]    st1_r;
    reg     signed  [CALC_WIDTH-1:0]    st1_l;
    reg     signed  [CALC_WIDTH-1:0]    st1_v0;
    reg     signed  [CALC_WIDTH-1:0]    st1_v1;
    reg     signed  [CALC_WIDTH-1:0]    st1_h0;
    reg     signed  [CALC_WIDTH-1:0]    st1_h1;
    
    reg             [1:0]               st2_phase;
    reg     signed  [CALC_WIDTH-1:0]    st2_raw;
    reg     signed  [CALC_WIDTH-1:0]    st2_g;
    reg     signed  [CALC_WIDTH-1:0]    st2_a;
    reg     signed  [CALC_WIDTH-1:0]    st2_b;
    reg     signed  [CALC_WIDTH-1:0]    st2_r;
    reg     signed  [CALC_WIDTH-1:0]    st2_l;
    reg     signed  [CALC_WIDTH-1:0]    st2_v;
    reg     signed  [CALC_WIDTH-1:0]    st2_h;
    
    reg             [1:0]               st3_phase;
    reg     signed  [CALC_WIDTH-1:0]    st3_raw;
    reg     signed  [CALC_WIDTH-1:0]    st3_g;
    reg     signed  [CALC_WIDTH-1:0]    st3_x;
    reg     signed  [CALC_WIDTH-1:0]    st3_v;
    reg     signed  [CALC_WIDTH-1:0]    st3_h;
    
    reg             [1:0]               st4_phase;
    reg     signed  [CALC_WIDTH-1:0]    st4_raw;
    reg     signed  [CALC_WIDTH-1:0]    st4_g;
    reg     signed  [CALC_WIDTH-1:0]    st4_x;
    reg     signed  [CALC_WIDTH-1:0]    st4_v;
    reg     signed  [CALC_WIDTH-1:0]    st4_h;
    
    reg     signed  [CALC_WIDTH-1:0]    st5_raw;
    reg     signed  [CALC_WIDTH-1:0]    st5_r;
    reg     signed  [CALC_WIDTH-1:0]    st5_g;
    reg     signed  [CALC_WIDTH-1:0]    st5_b;
    
    always @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_phase[0] <= ~st0_phase[0];
            if ( in_pixel_first ) begin
                if ( in_line_first ) begin
                    reg_param_phase <= param_phase;
                    st0_phase       <= param_phase;
                end
                else begin
                    st0_phase[0] <= reg_param_phase[0];
                    st0_phase[1] <= ~st0_phase[1];
                end
            end
            
            st0_raw <= in_raw22;
            st0_g   <= in_g22;
            
            st0_a0  <= in_g13 + in_g31;
            st0_a1  <= absdiff(in_raw13, in_raw31);
            st0_b0  <= in_g11 + in_g33;
            st0_b1  <= absdiff(in_raw11, in_raw33);
            st0_r   <= in_raw13 + in_raw31;
            st0_l   <= in_raw11 + in_raw33;
            
            st0_v0  <= in_raw12 + in_raw32;
            st0_v1  <= in_g12   + in_g32;
            
            st0_h0  <= in_raw21 + in_raw23;
            st0_h1  <= in_g21   + in_g23;
            
            
            // stage 1
            st1_phase <= st0_phase;
            st1_raw   <= st0_raw;
            st1_g     <= st0_g;
            
            st1_a0    <= st0_g * 2 - st0_a0;
            st1_a1    <= st0_a1;
            st1_b0    <= st0_g * 2 - st0_b0;
            st1_b1    <= st0_b1;
            st1_r     <= st0_r;
            st1_l     <= st0_l;
            
            st1_v0    <= st0_v0;
            st1_v1    <= st0_g * 2 - st0_v1;
            
            st1_h0    <= st0_h0;
            st1_h1    <= st0_g * 2 - st0_h1;
            
            
            // stage 2
            st2_phase <= st1_phase;
            st2_raw   <= st1_raw;
            st2_g     <= st1_g;
            
            st2_a     <= abs(st1_a0) + st1_a1;
            st2_b     <= abs(st1_b0) + st1_b1;
            st2_r     <= st1_r * 2 + st1_a0;
            st2_l     <= st1_l * 2 + st1_b0;
            st2_v     <= st1_v0 * 2 + st1_v1;
            st2_h     <= st1_h0 * 2 + st1_h1;
            
            
            // stage 3
            st3_phase <= st2_phase;
            st3_raw   <= st2_raw;
            st3_g     <= st2_g;
            st3_x     <= ((st2_a > st2_b ? st2_l : st2_r) + (st2_b > st2_a ? st2_r : st2_l)) >>> 3;
            st3_v     <= st2_v >>> 2;
            st3_h     <= st2_h >>> 2;
            
            
            // stage 4
            st4_phase <= st3_phase;
            st4_raw   <= st3_raw;
            st4_g     <= st3_g;
            st4_x     <= st3_x;
            st4_v     <= st3_v;
            st4_h     <= st3_h;
            if ( st3_x < {DATA_WIDTH{1'b0}} ) st4_x <= {DATA_WIDTH{1'b0}};
            if ( st3_x > {DATA_WIDTH{1'b1}} ) st4_x <= {DATA_WIDTH{1'b1}};
            if ( st3_v < {DATA_WIDTH{1'b0}} ) st4_v <= {DATA_WIDTH{1'b0}};
            if ( st3_v > {DATA_WIDTH{1'b1}} ) st4_v <= {DATA_WIDTH{1'b1}};
            if ( st3_h < {DATA_WIDTH{1'b0}} ) st4_h <= {DATA_WIDTH{1'b0}};
            if ( st3_h > {DATA_WIDTH{1'b1}} ) st4_h <= {DATA_WIDTH{1'b1}};
            
            
            // stage 5
            st5_raw <= st4_raw;
            case ( st4_phase )
            2'b00:  begin st5_r <= st4_raw; st5_g <= st4_g;   st5_b <= st4_x;   end
            2'b01:  begin st5_r <= st4_h;   st5_g <= st4_raw; st5_b <= st4_v;   end
            2'b10:  begin st5_r <= st4_v;   st5_g <= st4_raw; st5_b <= st4_h;   end
            2'b11:  begin st5_r <= st4_x;   st5_g <= st4_g;   st5_b <= st4_raw; end
            endcase
        end
    end
    
    assign  out_raw  = st5_raw;
    assign  out_r    = st5_r;
    assign  out_g    = st5_g;
    assign  out_b    = st5_b;
    
endmodule


`default_nettype wire


// end of file
