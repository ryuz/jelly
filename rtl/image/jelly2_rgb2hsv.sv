// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_rgb2hsv
        #(
            parameter   USER_WIDTH = 0,
            parameter   DATA_WIDTH = 8,
            
            parameter   USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                         reset,
            input   wire                         clk,
            input   wire                         cke,
            
            input   wire    [USER_BITS-1:0]      s_user,
            input   wire    [DATA_WIDTH-1:0]     s_r,
            input   wire    [DATA_WIDTH-1:0]     s_g,
            input   wire    [DATA_WIDTH-1:0]     s_b,
            input   wire                         s_valid,
            
            output  reg     [USER_BITS-1:0]      m_user,
            output  reg     [DATA_WIDTH-1:0]     m_h,
            output  reg     [DATA_WIDTH-1:0]     m_s,
            output  reg     [DATA_WIDTH-1:0]     m_v,
            output  reg                          m_valid
        );
    
    localparam H_UNIT = (1 << (DATA_WIDTH-3));

    function [DATA_WIDTH-1:0]   max_val(input [DATA_WIDTH-1:0] a, input [DATA_WIDTH-1:0] b);
    begin
        max_val = a > b ? a : b;
    end
    endfunction

    wire    compare_rg = (s_r > s_g);
    wire    compare_gb = (s_g > s_b);
    wire    compare_br = (s_b > s_r);

    logic           [USER_BITS-1:0]     st0_user;
    logic   signed  [DATA_WIDTH:0]      st0_r;
    logic   signed  [DATA_WIDTH:0]      st0_g;
    logic   signed  [DATA_WIDTH:0]      st0_b;
    logic           [1:0]               st0_sel;
    logic   signed  [DATA_WIDTH:0]      st0_max;
    logic   signed  [DATA_WIDTH:0]      st0_min;
    logic                               st0_valid;

    logic           [USER_BITS-1:0]     st1_user;
    logic   signed  [DATA_WIDTH:0]      st1_h;
    logic   signed  [DATA_WIDTH:0]      st1_s;
    logic   signed  [DATA_WIDTH:0]      st1_v;
    logic   signed  [DATA_WIDTH:0]      st1_offset;
    logic                               st1_valid;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_user <= s_user;
            st0_r    <= {1'b0, s_r};
            st0_g    <= {1'b0, s_g};
            st0_b    <= {1'b0, s_b};
            if ( compare_rg && !compare_br ) begin
                st0_sel <= 2'd0;
                st0_max <= {1'b0, s_r};
            end
            else if ( !compare_rg && compare_gb ) begin
                st0_sel <= 2'd1;
                st0_max <= {1'b0, s_g};
            end
            else begin
                st0_sel <= 2'd2;
                st0_max <= {1'b0, s_b};
            end

            if ( !compare_rg && compare_br ) begin
                st0_min <= {1'b0, s_r};
            end
            else if ( compare_rg && !compare_gb ) begin
                st0_min <= {1'b0, s_g};
            end
            else begin
                st0_min <= {1'b0, s_b};
            end

            // stage1
            st1_user <= st0_user;
            st1_s    <= st0_max - st0_min;
            st1_v    <= st0_max;
            case (st0_sel)
            2'd0:       begin st1_offset <= 1*H_UNIT; st1_h <= st0_g - st0_r; end
            2'd1:       begin st1_offset <= 3*H_UNIT; st1_h <= st0_b - st0_g; end
            2'd2:       begin st1_offset <= 5*H_UNIT; st1_h <= st0_r - st0_b; end
            default:    begin st1_offset <= 'x;       st1_h <= 'x;            end
            endcase
        end
    end
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_valid <= 1'b0;
            st1_valid <= 1'b0;
        end
        else if ( cke ) begin
            st0_valid <= s_valid;
            st1_valid <= st0_valid;
        end
    end


    logic           [USER_BITS-1:0]     div_user;
    logic   signed  [2*DATA_WIDTH:0]    div_h;
    logic   signed  [DATA_WIDTH:0]      div_s;
    logic   signed  [DATA_WIDTH:0]      div_v;
    logic   signed  [DATA_WIDTH:0]      div_offset;
    logic                               div_valid;

    jelly_integer_divider
            #(
                .USER_WIDTH          (USER_BITS+3*(1+DATA_WIDTH)),
                .S_DIVIDEND_WIDTH    (1+DATA_WIDTH*2),
                .S_DIVISOR_WIDTH     (1+DATA_WIDTH),
                .MASTER_IN_REGS      (1),
                .MASTER_OUT_REGS     (1),
                .DEVICE              ("RTL"),
                .NORMALIZE_REMAINDER (1), 
                .NORMALIZE_STAGES    (1)
            )
        i_integer_divider
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_user             ({st1_user, st1_s, st1_v, st1_offset}),
                .s_dividend         ({st1_h, {DATA_WIDTH{1'b0}}}),
                .s_divisor          (st1_s),
                .s_valid            (st1_valid),
                .s_ready            (),
                
                .m_user             ({div_user, div_s, div_v, div_offset}),
                .m_quotient         (div_h),
                .m_remainder        (),
                .m_valid            (div_valid),
                .m_ready            (1'b1)
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_user  <= 'x;
            m_h     <= 'x;
            m_s     <= 'x;
            m_v     <= 'x;
            m_valid <= 1'b0;
        end
        else if ( cke ) begin
            m_user  <= div_user;
            m_h     <= DATA_WIDTH'(div_h + (1+2*DATA_WIDTH)'(div_offset));
            m_s     <= DATA_WIDTH'(div_s);
            m_v     <= DATA_WIDTH'(div_v);
            m_valid <= div_valid;
        end
    end


endmodule


`default_nettype wire


// end of file
