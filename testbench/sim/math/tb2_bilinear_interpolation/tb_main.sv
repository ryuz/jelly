
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );


    parameter   int     USER_WIDTH    = 0;
    parameter   int     COMPONENT_NUM = 1;
    parameter   int     RATE_WIDTH    = 8;
    parameter   int     RATE_Q        = RATE_WIDTH;
    parameter   int     S_DATA_WIDTH  = 16;
    parameter   int     S_DATA_Q      = 0;
    parameter   bit     S_DATA_SIGNED = 1;
    parameter   int     M_DATA_WIDTH  = S_DATA_WIDTH + 8;
    parameter   int     M_DATA_Q      = S_DATA_Q + 8;
    parameter   bit     RATE_SIGNED   = 0;
    parameter   bit     DATA_SIGNED   = 1;
    parameter   bit     ROUNDING      = 0;
    
    localparam  int     USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1;

    logic                                           cke = 1'b1;
    
    logic   [USER_BITS-1:0]                         s_user;
    logic   [RATE_WIDTH-1:0]                        s_rate_x;
    logic   [RATE_WIDTH-1:0]                        s_rate_y;
    logic   [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data00;
    logic   [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data01;
    logic   [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data10;
    logic   [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data11;
    logic                                           s_valid;

    logic   [USER_BITS-1:0]                         m_user;
    logic   [COMPONENT_NUM-1:0][M_DATA_WIDTH-1:0]   m_data;
    logic                                           m_valid;

    jelly2_bilinear_interpolation
            #(
                .USER_WIDTH     (USER_WIDTH   ),
                .COMPONENT_NUM  (COMPONENT_NUM),
                .RATE_WIDTH     (RATE_WIDTH   ),
                .RATE_Q         (RATE_Q       ),
                .S_DATA_WIDTH   (S_DATA_WIDTH ),
                .S_DATA_Q       (S_DATA_Q     ),
                .S_DATA_SIGNED  (S_DATA_SIGNED),
                .M_DATA_WIDTH   (M_DATA_WIDTH ),
                .M_DATA_Q       (M_DATA_Q     ),
                .RATE_SIGNED    (RATE_SIGNED  ),
                .DATA_SIGNED    (DATA_SIGNED  ),
                .ROUNDING       (ROUNDING     )
                
            )
        i_bilinear_interpolation
            (
                .reset,
                .clk,
                .cke,
                
                .s_user,
                .s_rate_x,
                .s_rate_y,
                .s_data00,
                .s_data01,
                .s_data10,
                .s_data11,
                .s_valid,
                
                .m_user,
                .m_data,
                .m_valid
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            s_user   <= '0;
            s_rate_x <= '0;
            s_rate_y <= '0;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                s_data00[i] <= S_DATA_WIDTH'(1);
                s_data01[i] <= S_DATA_WIDTH'(200);
                s_data10[i] <= S_DATA_WIDTH'(300);
                s_data11[i] <= S_DATA_WIDTH'(400);
            end
            s_valid <= '0;
        end
        else if ( cke ) begin
            s_rate_x  <= s_rate_x + 0;
            s_rate_y  <= s_rate_y + 1;
            s_rate_x  <= 100;
            s_rate_y  <= 200;
            s_valid <= '1;
        end
    end

endmodule


`default_nettype wire


// end of file
