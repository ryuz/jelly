// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_box_core
        #(
            parameter   int                         ROWS         = 3,
            parameter   int                         COLS         = 3,
            parameter   int                         CENTER_Y     = (ROWS-1) / 2,
            parameter   int                         CENTER_X     = (COLS-1) / 2,
            parameter   int                         MAX_COLS     = 4096,
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 8,
            localparam  int                         COEFF_WIDTH  = 18,
            parameter   int                         COEFF_FRAC   = 8, 
            parameter   bit                         SIGNED       = 0,
            parameter                               BORDER_MODE  = "REPLICATE",
            parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}},
            parameter                               RAM_TYPE     = "block",
            parameter   bit                         ENDIAN       = 0,
            parameter   bit                         USE_VALID    = 1,
            
            localparam  int                         USER_BITS   = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                                    reset,
            input   wire                                                    clk,
            input   wire                                                    cke,
            
            input   wire    signed  [ROWS-1:0][COLS-1:0][COEFF_WIDTH-1:0]   param_coeff,
            input   wire                                [DATA_WIDTH-1:0]    param_min,
            input   wire                                [DATA_WIDTH-1:0]    param_max,

            input   wire                                                    s_img_row_first,
            input   wire                                                    s_img_row_last,
            input   wire                                                    s_img_col_first,
            input   wire                                                    s_img_col_last,
            input   wire                                                    s_img_de,
            input   wire            [USER_BITS-1:0]                         s_img_user,
            input   wire            [DATA_WIDTH-1:0]                        s_img_data,
            input   wire                                                    s_img_valid,
            
            output  wire                                                    m_img_row_first,
            output  wire                                                    m_img_row_last,
            output  wire                                                    m_img_col_first,
            output  wire                                                    m_img_col_last,
            output  wire                                                    m_img_de,
            output  wire            [USER_BITS-1:0]                         m_img_user,
            output  wire            [DATA_WIDTH-1:0]                        m_img_data,
            output  wire                                                    m_img_valid
        );
    
    
    wire                                            img_blk_row_first;
    wire                                            img_blk_row_last;
    wire                                            img_blk_col_first;
    wire                                            img_blk_col_last;
    wire    [USER_BITS-1:0]                         img_blk_user;
    wire                                            img_blk_de;
    wire    [ROWS-1:0][COLS-1:0][DATA_WIDTH-1:0]    img_blk_data;
    wire                                            img_blk_valid;
    
    jelly2_img_blk_buffer
            #(
                .N                  (ROWS),
                .M                  (COLS),
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .MAX_COLS           (MAX_COLS),
                .RAM_TYPE           (RAM_TYPE),
                .BORDER_MODE        (BORDER_MODE),
                .BORDER_VALUE       (BORDER_VALUE),
                .ENDIAN             (ENDIAN)
            )
        i_img_blk_buffer
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
                .s_img_data         (s_img_data),
                .s_img_valid        (s_img_valid),
                
                .m_img_row_first    (img_blk_row_first),
                .m_img_row_last     (img_blk_row_last),
                .m_img_col_first    (img_blk_col_first),
                .m_img_col_last     (img_blk_col_last),
                .m_img_de           (img_blk_de),
                .m_img_user         (img_blk_user),
                .m_img_data         (img_blk_data),
                .m_img_valid        (img_blk_valid)
            );
    
    
    jelly_img_box_calc
            #(
                .ROWS               (ROWS),
                .COLS               (COLS),
                .CENTER_Y           (CENTER_Y),
                .CENTER_X           (CENTER_X),
                .MAX_COLS           (MAX_COLS),
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .COEFF_INT          (COEFF_INT),
                .COEFF_FRAC         (COEFF_FRAC),
                .SIGNED             (SIGNED)
            )
        i_img_box_calc
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .in_data            (img_blk_data),
                
                .out_data           (m_img_data),
                .out_grad_x         (m_img_grad_x),
                .out_grad_y         (m_img_grad_y)
            );
    
    jelly2_img_delay
            #(
                .USER_WIDTH         (USER_WIDTH),
                .LATENCY            (5),
                .USE_VALID          (USE_VALID)
            )
        i_img_delay
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_img_row_first    (img_blk_row_first),
                .s_img_row_last     (img_blk_row_last),
                .s_img_col_first    (img_blk_col_first),
                .s_img_col_last     (img_blk_col_last),
                .s_img_de           (img_blk_de),
                .s_img_user         (img_blk_user),
                .s_img_valid        (img_blk_valid),
                
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
