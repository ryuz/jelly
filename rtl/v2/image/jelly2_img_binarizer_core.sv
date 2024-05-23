// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_binarizer_core
        #(
            parameter   int     USER_WIDTH   = 0,
            parameter   int     S_COMPONENTS = 1,
            parameter   int     S_DATA_WIDTH = 8,
            parameter   int     M_COMPONENTS = 1,
            parameter   int     M_DATA_WIDTH = 1,
            parameter   bit     WRAP_AROUND  = 1,
            parameter   bit     USE_VALID    = 1'b1,
            
            parameter   int     USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                            reset,
            input   wire                                            clk,
            input   wire                                            cke,
            
            input   wire                                            param_or,
            input   wire    [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    param_th0,
            input   wire    [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    param_th1,
            input   wire    [S_COMPONENTS-1:0]                      param_inv,
            input   wire    [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    param_val0,
            input   wire    [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    param_val1,
            
            input   wire                                            s_img_row_first,
            input   wire                                            s_img_row_last,
            input   wire                                            s_img_col_first,
            input   wire                                            s_img_col_last,
            input   wire                                            s_img_de,
            input   wire    [USER_BITS-1:0]                         s_img_user,
            input   wire    [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    s_img_data,
            input   wire                                            s_img_valid,
            
            output  wire                                            m_img_row_first,
            output  wire                                            m_img_row_last,
            output  wire                                            m_img_col_first,
            output  wire                                            m_img_col_last,
            output  wire                                            m_img_de,
            output  wire    [USER_BITS-1:0]                         m_img_user,
            output  wire    [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    m_img_data,
            output  wire                                            m_img_valid
        );
    
    
    jelly2_img_binarizer_calc
            #(
                .S_COMPONENTS       (S_COMPONENTS),
                .S_DATA_WIDTH       (S_DATA_WIDTH),
                .M_COMPONENTS       (M_COMPONENTS),
                .M_DATA_WIDTH       (M_DATA_WIDTH),
                .WRAP_AROUND        (WRAP_AROUND )
            )
        i_img_binarizer_calc
            (
                .reset,
                .clk,
                .cke,
                
                .param_or,
                .param_th0,
                .param_th1,
                .param_inv,
                .param_val0,
                .param_val1,
                
                .s_data             (s_img_data),
                .m_data             (m_img_data)
            );
    
    jelly2_img_delay
            #(
                .USER_WIDTH         (USER_WIDTH),
                .LATENCY            (4),
                .USE_VALID          (USE_VALID)
            )
        i_img_delay
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_img_row_first    (s_img_row_first),
                .s_img_row_last     (s_img_row_last),
                .s_img_col_first    (s_img_col_first),
                .s_img_col_last     (s_img_col_last),
                .s_img_de           (s_img_de),
                .s_img_user         (s_img_user),
                .s_img_valid        (s_img_valid),
                
                .m_img_row_first    (m_img_row_first),
                .m_img_row_last     (m_img_row_last),
                .m_img_col_first    (m_img_col_first),
                .m_img_col_last     (m_img_col_last),
                .m_img_de           (m_img_de),
                .m_img_user         (m_img_user),
                .m_img_valid        (m_img_valid)
            );
        
endmodule


`default_nettype wire


// end of file
