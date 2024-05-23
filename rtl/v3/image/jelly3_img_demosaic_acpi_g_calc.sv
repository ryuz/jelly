// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_g_calc
        #(
            parameter   int   DATA_BITS = 10,
            parameter   type  data_t    = logic [DATA_BITS-1:0],
            parameter   int   CALC_BITS = DATA_BITS + 6,
            parameter   type  calc_t    = logic signed  [CALC_BITS-1:0],
            localparam  type  phase_t   = logic [1:0]
        )
        (
            input   var logic               reset,
            input   var logic               clk,
            input   var logic               cke,
            input   var phase_t             param_phase,
            input   var logic               in_line_first,
            input   var logic               in_pixel_first,
            input   var data_t  [4:0][4:0]  in_raw,
            output  var data_t              out_raw,
            output  var data_t              out_g
        );
    
    
    // 計算用に余裕を持った幅を定義
    localparam type data_sign_t = logic signed [$bits(data_t):0];
    localparam DATA_SIGNED = data_sign_t'(data_t'(data_sign_t'(-1))) == data_sign_t'(-1);

    localparam calc_t   MAX_VALUE = DATA_SIGNED ? calc_t'($signed({1'b0, {($bits(data_t)-1){1'b1}}})) : calc_t'({1'b0, {$bits(data_t){1'b1}}});
    localparam calc_t   MIN_VALUE = DATA_SIGNED ? calc_t'($signed({1'b1, {($bits(data_t)-1){1'b0}}})) : calc_t'({1'b0, {$bits(data_t){1'b0}}});
    
    function calc_t  abs(input calc_t a);
        return a >= 0 ? a : -a;
    endfunction
    
    function calc_t absdiff(input calc_t a, input calc_t b);
        return a > b ? a - b : b - a;
    endfunction
    
    
    wire    calc_t  in_raw11 = calc_t'(in_raw[0][0]);
    wire    calc_t  in_raw12 = calc_t'(in_raw[0][1]);
    wire    calc_t  in_raw13 = calc_t'(in_raw[0][2]);
    wire    calc_t  in_raw14 = calc_t'(in_raw[0][3]);
    wire    calc_t  in_raw15 = calc_t'(in_raw[0][4]);
    wire    calc_t  in_raw21 = calc_t'(in_raw[1][0]);
    wire    calc_t  in_raw22 = calc_t'(in_raw[1][1]);
    wire    calc_t  in_raw23 = calc_t'(in_raw[1][2]);
    wire    calc_t  in_raw24 = calc_t'(in_raw[1][3]);
    wire    calc_t  in_raw25 = calc_t'(in_raw[1][4]);
    wire    calc_t  in_raw31 = calc_t'(in_raw[2][0]);
    wire    calc_t  in_raw32 = calc_t'(in_raw[2][1]);
    wire    calc_t  in_raw33 = calc_t'(in_raw[2][2]);
    wire    calc_t  in_raw34 = calc_t'(in_raw[2][3]);
    wire    calc_t  in_raw35 = calc_t'(in_raw[2][4]);
    wire    calc_t  in_raw41 = calc_t'(in_raw[3][0]);
    wire    calc_t  in_raw42 = calc_t'(in_raw[3][1]);
    wire    calc_t  in_raw43 = calc_t'(in_raw[3][2]);
    wire    calc_t  in_raw44 = calc_t'(in_raw[3][3]);
    wire    calc_t  in_raw45 = calc_t'(in_raw[3][4]);
    wire    calc_t  in_raw51 = calc_t'(in_raw[4][0]);
    wire    calc_t  in_raw52 = calc_t'(in_raw[4][1]);
    wire    calc_t  in_raw53 = calc_t'(in_raw[4][2]);
    wire    calc_t  in_raw54 = calc_t'(in_raw[4][3]);
    wire    calc_t  in_raw55 = calc_t'(in_raw[4][4]);
    
    phase_t     reg_param_phase;

    phase_t     st0_phase;
    calc_t      st0_raw;
    calc_t      st0_a0;
    calc_t      st0_a1;
    calc_t      st0_b0;
    calc_t      st0_b1;
    calc_t      st0_v;
    calc_t      st0_h;
    
    phase_t     st1_phase;
    calc_t      st1_raw;
    calc_t      st1_a0;
    calc_t      st1_a1;
    calc_t      st1_b0;
    calc_t      st1_b1;
    calc_t      st1_v;
    calc_t      st1_h;
    
    phase_t     st2_phase;
    calc_t      st2_raw;
    calc_t      st2_a;
    calc_t      st2_b;
    calc_t      st2_v;
    calc_t      st2_h;
    
    phase_t     st3_phase;
    calc_t      st3_raw;
    calc_t      st3_g0;
    calc_t      st3_g1;
    
    phase_t     st4_phase;
    calc_t      st4_raw;
    calc_t      st4_g;
    
    phase_t     st5_phase;
    calc_t      st5_raw;
    calc_t      st5_g;

    phase_t     st6_phase;
    calc_t      st6_raw;
    calc_t      st6_g;
    
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

            st0_raw <= in_raw33;
            st0_a0  <= in_raw13 + in_raw53;
            st0_a1  <= absdiff(in_raw23, in_raw43);
            st0_b0  <= in_raw31 + in_raw35;
            st0_b1  <= absdiff(in_raw32, in_raw34);
            st0_v   <= in_raw23 + in_raw43;
            st0_h   <= in_raw32 + in_raw34;

            // stage 1
            st1_phase <= st0_phase;
            st1_raw   <= st0_raw;
            st1_a0    <= st0_raw * 2 - st0_a0;
            st1_a1    <= st0_a1;
            st1_b0    <= st0_raw * 2 - st0_b0;
            st1_b1    <= st0_b1;
            st1_v     <= st0_v;
            st1_h     <= st0_h;
            
            // stage 2
            st2_phase <= st1_phase;
            st2_raw   <= st1_raw;
            st2_a     <= abs(st1_a0) + st1_a1;
            st2_b     <= abs(st1_b0) + st1_b1;
            st2_v     <= st1_v * 2 + st1_a0;
            st2_h     <= st1_h * 2 + st1_b0;
            
            // stage 3
            st3_phase <= st2_phase;
            st3_raw   <= st2_raw;
            st3_g0    <= (st2_a < st2_b ? st2_v : st2_h);
            st3_g1    <= (st2_a > st2_b ? st2_h : st2_v);
            
            // stage 4
            st4_phase <= st3_phase;
            st4_raw   <= st3_raw;
            st4_g     <= (st3_g0 + st3_g1) >>> 3;
            
            // stage 5
            st5_phase <= st4_phase;
            st5_raw   <= st4_raw;
            st5_g     <= st4_g;
            if ( st4_g < MIN_VALUE ) begin st5_g <= MIN_VALUE; end
            if ( st4_g > MAX_VALUE ) begin st5_g <= MAX_VALUE; end

            // stage 6
            st6_raw <= st5_raw;
            case ( st5_phase )
            2'b00:  begin st6_g <= st5_g;   end
            2'b01:  begin st6_g <= st5_raw; end
            2'b10:  begin st6_g <= st5_raw; end
            2'b11:  begin st6_g <= st5_g;   end
            endcase
        end
    end
    
    assign  out_raw  = data_t'(st6_raw);
    assign  out_g    = data_t'(st6_g  );
    
endmodule


`default_nettype wire


// end of file
