// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_sobel_calc
        #(
            parameter   int     USER_WIDTH   = 0,
            parameter   int     DATA_WIDTH   = 8,
            parameter   int     GRAD_X_WIDTH = DATA_WIDTH + 2,
            parameter   int     GRAD_Y_WIDTH = DATA_WIDTH + 2,
            parameter   bit     SIGNED       = 0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,
            
            input   wire            [2:0][2:0][DATA_WIDTH-1:0]  in_data,
            
            output  wire            [DATA_WIDTH-1:0]            out_data,
            output  wire    signed  [GRAD_X_WIDTH-1:0]          out_grad_x,
            output  wire    signed  [GRAD_Y_WIDTH-1:0]          out_grad_y
        );

    localparam  int     GRAD_WIDTH = GRAD_X_WIDTH > GRAD_Y_WIDTH ? GRAD_X_WIDTH : GRAD_Y_WIDTH;
    localparam  int     CALC_WIDTH = GRAD_WIDTH   > DATA_WIDTH+2 ? GRAD_WIDTH   : DATA_WIDTH+2;
    
    wire    signed  [CALC_WIDTH-1:0]    grad_x_min = $signed({1'b1, {(GRAD_X_WIDTH-1){1'b0}}});
    wire    signed  [CALC_WIDTH-1:0]    grad_x_max = $signed({1'b0, {(GRAD_X_WIDTH-1){1'b1}}});
    wire    signed  [CALC_WIDTH-1:0]    grad_y_min = $signed({1'b1, {(GRAD_Y_WIDTH-1){1'b0}}});
    wire    signed  [CALC_WIDTH-1:0]    grad_y_max = $signed({1'b0, {(GRAD_Y_WIDTH-1){1'b1}}});
    
    wire    signed  [CALC_WIDTH-1:0]    in_data00 = SIGNED ? CALC_WIDTH'($signed(in_data[0][0])) : CALC_WIDTH'($unsigned(in_data[0][0]));
    wire    signed  [CALC_WIDTH-1:0]    in_data01 = SIGNED ? CALC_WIDTH'($signed(in_data[0][1])) : CALC_WIDTH'($unsigned(in_data[0][1]));
    wire    signed  [CALC_WIDTH-1:0]    in_data02 = SIGNED ? CALC_WIDTH'($signed(in_data[0][2])) : CALC_WIDTH'($unsigned(in_data[0][2]));
    wire    signed  [CALC_WIDTH-1:0]    in_data10 = SIGNED ? CALC_WIDTH'($signed(in_data[1][0])) : CALC_WIDTH'($unsigned(in_data[1][0]));
    wire    signed  [CALC_WIDTH-1:0]    in_data11 = SIGNED ? CALC_WIDTH'($signed(in_data[1][1])) : CALC_WIDTH'($unsigned(in_data[1][1]));
    wire    signed  [CALC_WIDTH-1:0]    in_data12 = SIGNED ? CALC_WIDTH'($signed(in_data[1][2])) : CALC_WIDTH'($unsigned(in_data[1][2]));
    wire    signed  [CALC_WIDTH-1:0]    in_data20 = SIGNED ? CALC_WIDTH'($signed(in_data[2][0])) : CALC_WIDTH'($unsigned(in_data[2][0]));
    wire    signed  [CALC_WIDTH-1:0]    in_data21 = SIGNED ? CALC_WIDTH'($signed(in_data[2][1])) : CALC_WIDTH'($unsigned(in_data[2][1]));
    wire    signed  [CALC_WIDTH-1:0]    in_data22 = SIGNED ? CALC_WIDTH'($signed(in_data[2][2])) : CALC_WIDTH'($unsigned(in_data[2][2]));
    
    reg             [DATA_WIDTH-1:0]    st0_data;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_x0;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_x1;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_x2;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_y0;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_y1;
    reg     signed  [CALC_WIDTH-1:0]    st0_grad_y2;
    
    reg             [DATA_WIDTH-1:0]    st1_data;
    reg     signed  [CALC_WIDTH-1:0]    st1_grad_x0;
    reg     signed  [CALC_WIDTH-1:0]    st1_grad_x1;
    reg     signed  [CALC_WIDTH-1:0]    st1_grad_y0;
    reg     signed  [CALC_WIDTH-1:0]    st1_grad_y1;
    
    reg             [DATA_WIDTH-1:0]    st2_data;
    reg     signed  [CALC_WIDTH-1:0]    st2_grad_x;
    reg     signed  [CALC_WIDTH-1:0]    st2_grad_y;
    
    reg             [DATA_WIDTH-1:0]    st3_data;
    reg     signed  [CALC_WIDTH-1:0]    st3_grad_x;
    reg     signed  [CALC_WIDTH-1:0]    st3_grad_y;
    reg                                 st3_min_x;
    reg                                 st3_max_x;
    reg                                 st3_min_y;
    reg                                 st3_max_y;
    
    reg             [DATA_WIDTH-1:0]    st4_data;
    reg     signed  [CALC_WIDTH-1:0]  st4_grad_x;
    reg     signed  [CALC_WIDTH-1:0]  st4_grad_y;
    
    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage0
            st0_data    <= in_data[1][1];
            st0_grad_x0 <= in_data00 - in_data02;
            st0_grad_x1 <= in_data10 - in_data12;
            st0_grad_x2 <= in_data20 - in_data22;
            st0_grad_y0 <= in_data00 - in_data20;
            st0_grad_y1 <= in_data01 - in_data21;
            st0_grad_y2 <= in_data02 - in_data22;
            
            // stage1
            st1_data    <= st0_data;
            st1_grad_x0 <= st0_grad_x0 + st0_grad_x2;
            st1_grad_x1 <= (st0_grad_x1 <<< 1);
            st1_grad_y0 <= st0_grad_y0 + st0_grad_y2;
            st1_grad_y1 <= (st0_grad_y1 <<< 1);
            
            // stage2
            st2_data    <= st1_data;
            st2_grad_x  <= st1_grad_x0 + st1_grad_x1;
            st2_grad_y  <= st1_grad_y0 + st1_grad_y1;
            
            // stage3
            st3_data    <= st2_data;
            st3_grad_x  <= st2_grad_x;
            st3_grad_y  <= st2_grad_y;
            st3_min_x   <= (st2_grad_x < grad_x_min);
            st3_max_x   <= (st2_grad_x > grad_x_max);
            st3_min_y   <= (st2_grad_y < grad_y_min);
            st3_max_y   <= (st2_grad_y > grad_y_max);
            
            // stage4
            st4_data    <= st3_data;
            st4_grad_x  <= st3_grad_x;
            st4_grad_y  <= st3_grad_y;
            if ( st3_min_x ) begin st4_grad_x <= grad_x_min; end
            if ( st3_max_x ) begin st4_grad_x <= grad_x_max; end
            if ( st3_min_y ) begin st4_grad_y <= grad_y_min; end
            if ( st3_max_y ) begin st4_grad_y <= grad_y_max; end
        end
    end
    
    assign out_data   = st4_data;
    assign out_grad_x = st4_grad_x;
    assign out_grad_y = st4_grad_y;
    
endmodule


`default_nettype wire


// end of file
