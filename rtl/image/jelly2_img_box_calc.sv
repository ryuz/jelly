// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_box_calc
        #(
            parameter   int     ROWS         = 3,
            parameter   int     COLS         = 3,
            parameter   int     MAX_COLS     = 4096,
            parameter   int     DATA_WIDTH   = 8,
            parameter   int     COEFF_WIDTH  = 18,
            parameter   int     COEFF_FRAC   = 8, 
            parameter   bit     SIGNED       = 0
        )
        (
            input   wire                                                    reset,
            input   wire                                                    clk,
            input   wire                                                    cke,
            
            input   wire    signed  [ROWS-1:0][COLS-1:0][COEFF_WIDTH-1:0]   param_coeff,
            input   wire                                [DATA_WIDTH-1:0]    param_min,
            input   wire                                [DATA_WIDTH-1:0]    param_max,

            input   wire            [ROWS-1:0][COLS-1:0][DATA_WIDTH-1:0]    in_data,
            output  reg                                 [DATA_WIDTH-1:0]    out_data
        );
    
    localparam  CALC_WIDTH = SIGNED ? DATA_WIDTH : DATA_WIDTH + 1;
    localparam  MUL_WIDTH  = COEFF_WIDTH + CALC_WIDTH;

    logic   signed                      [CALC_WIDTH-1:0]    min_value;
    logic   signed                      [CALC_WIDTH-1:0]    max_value;
    always_comb min_value = SIGNED ? CALC_WIDTH'($signed(param_min)) : CALC_WIDTH'($signed({1'b0, param_min}));
    always_comb max_value = SIGNED ? CALC_WIDTH'($signed(param_max)) : CALC_WIDTH'($signed({1'b0, param_max}));

    logic   signed  [ROWS-1:0][COLS-1:0][CALC_WIDTH-1:0]    st0_data;
    logic   signed  [ROWS-1:0][COLS-1:0][MUL_WIDTH-1:0]     st1_data;
    logic   signed                      [MUL_WIDTH-1:0]     st2_data;
    logic   signed                      [MUL_WIDTH-1:0]     st3_data;
    logic   signed                      [MUL_WIDTH-1:0]     st4_data;

    always_ff @(posedge clk) begin
        automatic logic signed  [MUL_WIDTH-1:0] tmp_data;

        // stage0
        for ( int i = 0; i < ROWS; ++i ) begin
            for ( int j = 0; j < COLS; ++j ) begin
                st0_data[i][j] <= SIGNED ? CALC_WIDTH'($signed(in_data[i][j])) : CALC_WIDTH'($signed({1'b0, in_data[i][j]}));
            end
        end

        // stage1
        for ( int i = 0; i < ROWS; ++i ) begin
            for ( int j = 0; j < COLS; ++j ) begin
                st1_data[i][j] <= st0_data[i][j] * param_coeff[i][j];
            end
        end

        // stage2
        tmp_data = '0;
        for ( int i = 0; i < ROWS; ++i ) begin
            for ( int j = 0; j < COLS; ++j ) begin
                tmp_data += st1_data[i][j];
            end
        end
        st2_data <= tmp_data;

        // stage3
        st3_data <= st2_data >>> COEFF_FRAC;
    end
    
    always_comb out_data = st3_data[DATA_WIDTH-1:0];
    
endmodule


`default_nettype wire


// end of file
