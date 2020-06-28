// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_mass_center
        #(
            parameter   DATA_WIDTH    = 8,
            parameter   Q_WIDTH       = 0,
            parameter   X_WIDTH       = 14 + Q_WIDTH,
            parameter   Y_WIDTH       = 14 + Q_WIDTH,
            parameter   X_COUNT_WIDTH = 32,
            parameter   Y_COUNT_WIDTH = 32,
            parameter   N_COUNT_WIDTH = 32,
            parameter   INIT_X        = (640 / 2) << Q_WIDTH,
            parameter   INIT_Y        = (132 / 2) << Q_WIDTH
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire                            s_img_line_first,
            input   wire                            s_img_line_last,
            input   wire                            s_img_pixel_first,
            input   wire                            s_img_pixel_last,
            input   wire                            s_img_de,
            input   wire    [DATA_WIDTH-1:0]        s_img_data,
            input   wire                            s_img_valid,
            
            output  wire    [X_WIDTH-1:0]           out_x,
            output  wire    [X_WIDTH-1:0]           out_y,
            output  wire                            out_valid
        );
    
    reg                             st0_first;
    reg                             st0_last;
    reg                             st0_de;
    reg     [DATA_WIDTH-1:0]        st0_data;
    reg     [X_COUNT_WIDTH-1:0]     st0_x;
    reg     [Y_COUNT_WIDTH-1:0]     st0_y;
    
    reg                             st1_first;
    reg                             st1_last;
    reg                             st1_de;
    reg     [DATA_WIDTH-1:0]        st1_data;
    reg     [X_COUNT_WIDTH-1:0]     st1_x;
    reg     [Y_COUNT_WIDTH-1:0]     st1_y;
    
    reg                             st2_last;
    reg                             st2_de;
    reg     [X_COUNT_WIDTH-1:0]     st2_x;
    reg     [Y_COUNT_WIDTH-1:0]     st2_y;
    reg     [N_COUNT_WIDTH-1:0]     st2_n;
    
    reg                             st3_zero;
    
    always @(posedge clk) begin
        if ( reset ) begin
            st0_first <= 1'b0;
            st0_last  <= 1'b0;
            st0_de    <= 1'b0;
            st0_data  <= {DATA_WIDTH{1'bx}};
            st0_x     <= {X_COUNT_WIDTH{1'bx}};
            st0_y     <= {Y_COUNT_WIDTH{1'bx}};
            
            st1_first <= 1'b0;
            st1_last  <= 1'b0;
            st1_de    <= 1'b0;
            st1_data  <= {DATA_WIDTH{1'bx}};
            st1_x     <= {X_COUNT_WIDTH{1'bx}};
            st1_y     <= {Y_COUNT_WIDTH{1'bx}};
            
            st2_last  <= 1'b0;
            st2_de    <= 1'b0;
            st2_x     <= {X_COUNT_WIDTH{1'bx}};
            st2_y     <= {Y_COUNT_WIDTH{1'bx}};
            
            st3_zero  <= 1'bx;
        end
        else if ( cke ) begin
            // stage 0
            st0_first <= (s_img_valid & s_img_line_first & s_img_pixel_first);
            st0_last  <= (s_img_valid & s_img_line_last  & s_img_pixel_last);
            st0_de    <= (s_img_valid & s_img_de);
            st0_data  <= (s_img_valid & s_img_de) ? s_img_data : 0;
            if ( s_img_valid ) begin
                st0_x <= st0_x + s_img_de;
                if ( s_img_pixel_first ) begin
                    st0_x <= 0;
                    st0_y <= st0_y + 1;
                    if ( s_img_line_first ) begin
                        st0_y <= 0;
                    end
                end
            end
            
            // stage 1
            st1_first <= st0_first;
            st1_last  <= st0_last;
            st1_de    <= st0_de;
            st1_data  <= st0_data;
            st1_x     <= st0_data * st0_x;
            st1_y     <= st0_data * st0_y;
            
            // stage 2
            st2_last <= st1_last;
            if ( st1_de ) begin
                if ( st1_first ) begin
                    st2_x <= st1_x;
                    st2_y <= st1_y;
                    st2_n <= st1_data;
                end
                else begin
                    st2_x <= st2_x + st1_x;
                    st2_y <= st2_y + st1_y;
                    st2_n <= st2_n + st1_data;
                end
            end
            
            // stage3
            if ( st2_last ) begin
                st3_zero <= (st2_n == 0);
            end
        end
    end
    
    
    // divider
    localparam XY_MAX_WIDTH = X_COUNT_WIDTH > Y_COUNT_WIDTH ? X_COUNT_WIDTH : Y_COUNT_WIDTH;
    localparam MAX_WIDTH    = XY_MAX_WIDTH  > N_COUNT_WIDTH ? XY_MAX_WIDTH  : N_COUNT_WIDTH;
    
    localparam DIV_WIDTH    = Q_WIDTH + MAX_WIDTH;
    
    wire    [DIV_WIDTH-1:0] st2_xx = st2_x << Q_WIDTH;
    wire    [DIV_WIDTH-1:0] st2_yy = st2_y << Q_WIDTH;
    
    wire    [DIV_WIDTH-1:0] div_x;
    wire    [DIV_WIDTH-1:0] div_y;
    wire                    div_valid;
    
    jelly_unsigned_divide_multicycle
            #(
                .DATA_WIDTH     (DIV_WIDTH)
            )
        i_unsigned_divide_multicycle_x
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (1'b1),
                
                .s_data0        (st2_xx),
                .s_data1        (st2_n),
                .s_valid        (st2_last),
                .s_ready        (),
                
                .m_quotient     (div_x),
                .m_remainder    (),
                .m_valid        (div_valid),
                .m_ready        (cke)
            );
    
    jelly_unsigned_divide_multicycle
            #(
                .DATA_WIDTH     (DIV_WIDTH)
            )
        i_unsigned_divide_multicycle_y
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (1'b1),
                
                .s_data0        (st2_yy),
                .s_data1        (st2_n),
                .s_valid        (st2_last),
                .s_ready        (),
                
                .m_quotient     (div_y),
                .m_remainder    (),
                .m_valid        (),
                .m_ready        (cke)
            );
    
    
    // output
    reg     [X_WIDTH-1:0]   reg_out_x;
    reg     [Y_WIDTH-1:0]   reg_out_y;
    reg                     reg_out_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_out_x     <= INIT_X;
            reg_out_y     <= INIT_Y;
            reg_out_valid <= 1'b0;
        end
        else if ( cke ) begin
            reg_out_valid <= 1'b0;
            if ( div_valid && !st3_zero ) begin
                reg_out_x     <= div_x;
                reg_out_y     <= div_y;
                reg_out_valid <= 1'b1;
            end
       end
    end
    
    assign out_x     = reg_out_x;
    assign out_y     = reg_out_y;
    assign out_valid = reg_out_valid;
    
endmodule


`default_nettype wire


// end of file
