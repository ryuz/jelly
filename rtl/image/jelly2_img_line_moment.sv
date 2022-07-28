// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_line_moment
        #(
            parameter   int     M0_WIDTH = 12,
            parameter   int     M1_WIDTH = 20
        )
        (
            input   wire                    reset,
            input   wire                    clk,
            input   wire                    cke,

            input   wire                    s_img_row_first,
            input   wire                    s_img_row_last,
            input   wire                    s_img_col_first,
            input   wire                    s_img_col_last,
            input   wire                    s_img_de,
            input   wire    [0:0]           s_img_data,
            input   wire                    s_img_valid,
            
            output  reg                     m_moment_first,
            output  reg                     m_moment_last,
            output  reg     [M0_WIDTH-1:0]  m_moment_m0,
            output  reg     [M1_WIDTH-1:0]  m_moment_m1,
            output  reg                     m_moment_valid
        );
    
    logic   [M0_WIDTH-1:0]      acc_x;
    logic   [M0_WIDTH-1:0]      acc_m0;
    logic   [M1_WIDTH-1:0]      acc_m1;
    logic                       acc_first;
    logic                       acc_last;
    logic                       acc_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            acc_x     <= 'x;
            acc_m0    <= 'x;
            acc_m1    <= 'x;
            acc_first <= 1'bx;
            acc_last  <= 1'bx;
            acc_valid <= 1'b0;
        end
        else if ( cke ) begin
            acc_valid <= 1'b0;
            if ( s_img_valid ) begin
                if ( s_img_col_first ) begin
                    acc_x  <= M0_WIDTH'(0);
                    acc_m0 <= M0_WIDTH'(0);
                    acc_m1 <= M1_WIDTH'(0);
                    if ( s_img_de && s_img_data ) begin
                        acc_m0 <= M0_WIDTH'(1);
                        acc_m1 <= M1_WIDTH'(0);
                    end
                end
                else begin
                    if ( s_img_de ) begin
                        acc_x  <= acc_x  + M0_WIDTH'(1);
                        if ( s_img_data ) begin
                            acc_m0 <= acc_m0 + M0_WIDTH'(1);
                            acc_m1 <= acc_m1 + M1_WIDTH'(acc_x);
                        end
                    end
                end
                acc_first <= s_img_row_first;
                acc_last  <= s_img_row_last;
                acc_valid <= s_img_col_last;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_moment_first <= 1'bx;
            m_moment_last  <= 1'bx;
            m_moment_m0    <= 'x;
            m_moment_m1    <= 'x;
            m_moment_valid <= 1'b0;
        end
        else begin
            if ( acc_valid ) begin
                m_moment_first <= acc_first;
                m_moment_last  <= acc_last;
                m_moment_m0    <= acc_m0;
                m_moment_m1    <= acc_m1;
            end
            m_moment_valid <= acc_valid & cke;
        end
    end
    
endmodule


`default_nettype wire


// end of file
