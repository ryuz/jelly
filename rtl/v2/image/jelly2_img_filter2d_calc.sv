// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_filter2d_calc
        #(
            parameter   int     ROWS         = 3,
            parameter   int     COLS         = 3,
            parameter   int     DATA_WIDTH   = 8,
            parameter   int     COEFF_WIDTH  = 18,
            parameter   int     COEFF_FRAC   = 16,
            parameter   int     MAC_WIDTH    = DATA_WIDTH + COEFF_WIDTH,
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

    logic   signed  [MAC_WIDTH-1:0]     min_value;
    logic   signed  [MAC_WIDTH-1:0]     max_value;
    always_comb min_value = SIGNED ? MAC_WIDTH'($signed(param_min)) : MAC_WIDTH'($signed({1'b0, param_min}));
    always_comb max_value = SIGNED ? MAC_WIDTH'($signed(param_max)) : MAC_WIDTH'($signed({1'b0, param_max}));


    logic   signed  [ROWS-1:0][COLS-1:0][CALC_WIDTH-1:0]    mac_in_data;
    logic   signed  [MAC_WIDTH-1:0]                         mac_out_data;
    always_comb begin
        for ( int i = 0; i < ROWS; ++i ) begin
            for ( int j = 0; j < COLS; ++j ) begin
                mac_in_data[i][j] = SIGNED ? CALC_WIDTH'($signed(in_data[i][j])) : CALC_WIDTH'($signed({1'b0, in_data[i][j]}));
            end
        end
    end

    jelly2_mul_add_array
            #(
                .N                  (ROWS*COLS),
                .MAC_WIDTH          (MAC_WIDTH),
                .COEFF_WIDTH        (COEFF_WIDTH),
                .DATA_WIDTH         (CALC_WIDTH)
            )
        i_mul_add_array
            (
                .reset,
                .clk,
                .cke,

                .param_coeff        (param_coeff),

                .s_add              ('0),
                .s_data             (mac_in_data),
                .s_valid            (1'b1),

                .m_data             (mac_out_data),
                .m_valid            ()
            );

    always_ff @(posedge clk) begin
        if ( cke ) begin
            automatic logic signed  [MAC_WIDTH-1:0] tmp_data;
            tmp_data = (mac_out_data >>> COEFF_FRAC);
            if ( tmp_data < min_value ) begin tmp_data = min_value; end
            if ( tmp_data > max_value ) begin tmp_data = max_value; end
            out_data <= tmp_data[DATA_WIDTH-1:0];
        end
    end
    
endmodule


`default_nettype wire


// end of file
