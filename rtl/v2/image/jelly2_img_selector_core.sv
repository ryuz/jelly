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
    
    // DIP-SW の接続なども考慮
    (* ASYNC_REG="true" *)  reg     [SEL_WIDTH-1:0]   ff0_sel, ff1_sel;
    always_ff @(posedge clk) begin
        ff0_sel <= sel;
        ff1_sel <= ff0_sel;
    end
    
    logic                       busy;
    logic   [SEL_WIDTH-1:0]     next_sel;
    logic   [SEL_WIDTH-1:0]     current_sel;
    always_comb next_sel = ff1_sel;
    
    wire                        img_next_row_first    = s_img_row_first[next_sel];
    wire                        img_next_row_last     = s_img_row_last [next_sel];
    wire                        img_next_col_first    = s_img_col_first[next_sel];
    wire                        img_next_col_last     = s_img_col_last [next_sel];
    wire                        img_next_de           = s_img_de       [next_sel];
    wire    [USER_BITS-1:0]     img_next_user         = s_img_user     [next_sel];
    wire    [DATA_WIDTH-1:0]    img_next_data         = s_img_data     [next_sel];
    wire                        img_next_valid        = s_img_valid    [next_sel];

    wire                        img_current_row_first = s_img_row_first[current_sel];
    wire                        img_current_row_last  = s_img_row_last [current_sel];
    wire                        img_current_col_first = s_img_col_first[current_sel];
    wire                        img_current_col_last  = s_img_col_last [current_sel];
    wire                        img_current_de        = s_img_de       [current_sel];
    wire    [USER_BITS-1:0]     img_current_user      = s_img_user     [current_sel];
    wire    [DATA_WIDTH-1:0]    img_current_data      = s_img_data     [current_sel];
    wire                        img_current_valid     = s_img_valid    [current_sel];

    wire                        next_frame_start    = (img_next_valid & img_next_row_first & img_next_col_first);
    wire                        current_frame_end   = (m_img_valid & m_img_row_last  & m_img_col_last);

    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy            <= 1'b0;
            current_sel     <= ff1_sel;
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
            if ( !busy || current_frame_end ) begin
                busy            <= next_frame_start;
                current_sel     <= next_sel;
                m_img_row_first <= img_next_row_first;
                m_img_row_last  <= img_next_row_last; 
                m_img_col_first <= img_next_col_first;
                m_img_col_last  <= img_next_col_last;
                m_img_de        <= img_next_de;
                m_img_user      <= img_next_user;
                m_img_data      <= img_next_data;
                m_img_valid     <= img_next_valid; 
            end
            else begin
                m_img_row_first <= img_current_row_first;
                m_img_row_last  <= img_current_row_last; 
                m_img_col_first <= img_current_col_first;
                m_img_col_last  <= img_current_col_last;
                m_img_de        <= img_current_de;
                m_img_user      <= img_current_user;
                m_img_data      <= img_current_data;
                m_img_valid     <= img_current_valid; 
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
