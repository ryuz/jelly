// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_img_selector_core
        #(
            parameter   int     NUM          = 2,
            parameter   int     SEL_WIDTH    = 1,
            parameter   int     USER_WIDTH   = 0,
            parameter   int     DATA_WIDTH   = 32,
            
            localparam  int     USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire    [SEL_WIDTH-1:0]             sel,
            
            input   wire    [NUM-1:0]                   s_img_row_first,
            input   wire    [NUM-1:0]                   s_img_row_last,
            input   wire    [NUM-1:0]                   s_img_col_first,
            input   wire    [NUM-1:0]                   s_img_col_last,
            input   wire    [NUM-1:0]                   s_img_de,
            input   wire    [NUM-1:0][USER_BITS-1:0]    s_img_user,
            input   wire    [NUM-1:0][DATA_WIDTH-1:0]   s_img_data,
            input   wire    [NUM-1:0]                   s_img_valid,
            
            output  reg                                 m_img_row_first,
            output  reg                                 m_img_row_last,
            output  reg                                 m_img_col_first,
            output  reg                                 m_img_col_last,
            output  reg                                 m_img_de,
            output  reg     [USER_BITS-1:0]             m_img_user,
            output  reg     [DATA_WIDTH-1:0]            m_img_data,
            output  reg                                 m_img_valid
        );
    
    // 厳密にはNGだがデバッグ色の強いコアなので手を抜く
    (* ASYNC_REG="true" *)  reg     [SEL_WIDTH-1:0]   ff0_sel, ff1_sel;
    always @(posedge clk) begin
        ff0_sel <= sel;
        ff1_sel <= ff0_sel;
    end
    
    
    logic                       busy;
    logic                       change;
    logic   [SEL_WIDTH-1:0]     current_sel;
    
    logic                       reg_row_first;
    logic                       reg_row_last;
    logic                       reg_col_first;
    logic                       reg_col_last;
    logic                       reg_de;
    logic   [USER_BITS-1:0]     reg_user;
    logic   [DATA_WIDTH-1:0]    reg_data;
    logic                       reg_valid;
    
    wire                        sel_row_first  = s_img_row_first[current_sel];
    wire                        sel_row_last   = s_img_row_last [current_sel];
    wire                        sel_col_first  = s_img_col_first[current_sel];
    wire                        sel_col_last   = s_img_col_last [current_sel];
    wire                        sel_de         = s_img_de       [current_sel];
    wire    [USER_BITS-1:0]     sel_user       = s_img_user     [current_sel];
    wire    [DATA_WIDTH-1:0]    sel_data       = s_img_data     [current_sel];
    wire                        sel_valid      = s_img_valid    [current_sel];
    
    wire                        frame_start = (sel_valid & sel_row_first & sel_col_first);
    wire                        frame_end   = (reg_valid & reg_row_last  & reg_col_last);
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy        <= 1'b0;
            change      <= 1'b0;
            current_sel <= ff1_sel;
        end
        else if ( cke ) begin
            change <= (current_sel != ff1_sel);
            
            if ( frame_start && !change ) begin
                busy <= 1'b1;
            end
            else if ( frame_end ) begin
                busy <= 1'b0;
            end
            
            if ( !frame_start && !busy ) begin
                current_sel <= ff1_sel;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_img_row_first <= 1'b0;
            m_img_row_last  <= 1'b0;
            m_img_col_first <= 1'b0;
            m_img_col_last  <= 1'b0;
            m_img_de        <= 1'b0;
            m_img_user      <= 'x;
            m_img_data      <= 'x;
            m_img_valid     <= 1'b0;
        end
        else if ( cke ) begin           
            m_img_row_first <= sel_row_first;
            m_img_row_last  <= sel_row_last;
            m_img_col_first <= sel_col_first;
            m_img_col_last  <= sel_col_last;
            m_img_de        <= sel_de;
            m_img_user      <= sel_user;
            m_img_data      <= sel_data;
            m_img_valid     <= sel_valid;
        end
    end
    
endmodule


`default_nettype wire


// end of file
