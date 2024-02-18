// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_rb_calc
        #(
            parameter   int   DATA_BITS = 10,
            parameter   type  data_t    = logic [DATA_BITS-1:0],
            parameter   int   CALC_BITS = DATA_BITS + 6,
            parameter   type  calc_t    = logic signed  [CALC_BITS-1:0],
            localparam  type  phase_t   = logic [1:0]        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,
            
            input   var phase_t                     param_phase,
            
            input   var logic                       in_line_first,
            input   var logic                       in_pixel_first,
            input   var data_t  [2:0][2:0][1:0]     in_data,
            
            output  var data_t                      out_raw,
            output  var data_t                      out_r,
            output  var data_t                      out_g,
            output  var data_t                      out_b
        );
    
    
    // 計算用に余裕を持った幅を定義
    localparam type data_sign_t = logic signed [$bits(data_t):0];
    localparam DATA_SIGNED = data_sign_t'(data_t'(data_sign_t'(-1))) == data_sign_t'(-1);

    localparam calc_t   MAX_VALUE = DATA_SIGNED ? calc_t'({1'b0, {($bits(data_t)-1){1'b1}}}) : calc_t'({1'b0, {$bits(data_t){1'b1}}});
    localparam calc_t   MIN_VALUE = DATA_SIGNED ? calc_t'({1'b1, {($bits(data_t)-1){1'b0}}}) : calc_t'({1'b0, {$bits(data_t){1'b0}}});
    
    function calc_t  abs(input calc_t a);
        return a >= 0 ? a : -a;
    endfunction
    
    function calc_t absdiff(input calc_t a, input calc_t b);
        return a > b ? a - b : b - a;
    endfunction
    
    
    wire    calc_t  in_raw11 = calc_t'(in_data[0][0][0]);
    wire    calc_t  in_raw12 = calc_t'(in_data[0][1][0]);
    wire    calc_t  in_raw13 = calc_t'(in_data[0][2][0]);
    wire    calc_t  in_raw21 = calc_t'(in_data[1][0][0]);
    wire    calc_t  in_raw22 = calc_t'(in_data[1][1][0]);
    wire    calc_t  in_raw23 = calc_t'(in_data[1][2][0]);
    wire    calc_t  in_raw31 = calc_t'(in_data[2][0][0]);
    wire    calc_t  in_raw32 = calc_t'(in_data[2][1][0]);
    wire    calc_t  in_raw33 = calc_t'(in_data[2][2][0]);   
    wire    calc_t  in_g11   = calc_t'(in_data[0][0][1]);
    wire    calc_t  in_g12   = calc_t'(in_data[0][1][1]);
    wire    calc_t  in_g13   = calc_t'(in_data[0][2][1]);
    wire    calc_t  in_g21   = calc_t'(in_data[1][0][1]);
    wire    calc_t  in_g22   = calc_t'(in_data[1][1][1]);
    wire    calc_t  in_g23   = calc_t'(in_data[1][2][1]);
    wire    calc_t  in_g31   = calc_t'(in_data[2][0][1]);
    wire    calc_t  in_g32   = calc_t'(in_data[2][1][1]);
    wire    calc_t  in_g33   = calc_t'(in_data[2][2][1]);
    
    phase_t     reg_param_phase;
    
    phase_t     st0_phase;
    calc_t      st0_raw;
    calc_t      st0_g;
    calc_t      st0_a0;
    calc_t      st0_a1;
    calc_t      st0_b0;
    calc_t      st0_b1;
    calc_t      st0_r;
    calc_t      st0_l;
    calc_t      st0_v0;
    calc_t      st0_v1;
    calc_t      st0_h0;
    calc_t      st0_h1;
    
    phase_t     st1_phase;
    calc_t      st1_raw;
    calc_t      st1_g;
    calc_t      st1_a0;
    calc_t      st1_a1;
    calc_t      st1_b0;
    calc_t      st1_b1;
    calc_t      st1_r;
    calc_t      st1_l;
    calc_t      st1_v0;
    calc_t      st1_v1;
    calc_t      st1_h0;
    calc_t      st1_h1;
    
    phase_t     st2_phase;
    calc_t      st2_raw;
    calc_t      st2_g;
    calc_t      st2_a;
    calc_t      st2_b;
    calc_t      st2_r;
    calc_t      st2_l;
    calc_t      st2_v;
    calc_t      st2_h;
    
    phase_t     st3_phase;
    calc_t      st3_raw;
    calc_t      st3_g;
    calc_t      st3_x0;
    calc_t      st3_x1;
    calc_t      st3_v;
    calc_t      st3_h;
    
    phase_t     st4_phase;
    calc_t      st4_raw;
    calc_t      st4_g;
    calc_t      st4_x;
    calc_t      st4_v;
    calc_t      st4_h;
    
    phase_t     st5_phase;
    calc_t      st5_raw;
    calc_t      st5_g;
    calc_t      st5_x;
    calc_t      st5_v;
    calc_t      st5_h;
    
    calc_t      st6_raw;
    calc_t      st6_r;
    calc_t      st6_g;
    calc_t      st6_b;
    
    always_ff @(posedge clk) begin
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
            st3_x0    <= (st2_a > st2_b ? st2_l : st2_r);
            st3_x1    <= (st2_b > st2_a ? st2_r : st2_l);
            st3_v     <= st2_v;
            st3_h     <= st2_h;
            
            
            // stage 4
            st4_phase <= st3_phase;
            st4_raw   <= st3_raw;
            st4_g     <= st3_g;
            st4_x     <= (st3_x0 + st3_x1) >>> 3;
            st4_v     <= st3_v >>> 2;
            st4_h     <= st3_h >>> 2;
            
            
            // stage 5
            st5_phase <= st4_phase;
            st5_raw   <= st4_raw;
            st5_g     <= st4_g;
            st5_x     <= st4_x;
            st5_v     <= st4_v;
            st5_h     <= st4_h;
            if ( st4_x < MIN_VALUE ) begin st5_x <= MIN_VALUE; end
            if ( st4_x > MAX_VALUE ) begin st5_x <= MAX_VALUE; end
            if ( st4_v < MIN_VALUE ) begin st5_v <= MIN_VALUE; end
            if ( st4_v > MAX_VALUE ) begin st5_v <= MAX_VALUE; end
            if ( st4_h < MIN_VALUE ) begin st5_h <= MIN_VALUE; end
            if ( st4_h > MAX_VALUE ) begin st5_h <= MAX_VALUE; end
            
            
            // stage 6
            st6_raw <= st5_raw;
            st6_g   <= st5_g;
            case ( st5_phase )
            2'b00:  begin st6_r <= st5_raw; st6_b <= st5_x;   end
            2'b01:  begin st6_r <= st5_h;   st6_b <= st5_v;   end
            2'b10:  begin st6_r <= st5_v;   st6_b <= st5_h;   end
            2'b11:  begin st6_r <= st5_x;   st6_b <= st5_raw; end
            endcase
        end
    end
    
    assign  out_raw  = data_t'(st6_raw);
    assign  out_r    = data_t'(st6_r);
    assign  out_g    = data_t'(st6_g);
    assign  out_b    = data_t'(st6_b);
    
endmodule


`default_nettype wire


// end of file
