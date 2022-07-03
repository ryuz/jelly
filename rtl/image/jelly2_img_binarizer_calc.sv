// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_binarizer_calc
        #(
            parameter   int     S_COMPONENTS = 1,
            parameter   int     S_DATA_WIDTH = 8,
            parameter   int     M_COMPONENTS = 1,
            parameter   int     M_DATA_WIDTH = 1,
            parameter   bit     WRAP_AROUND  = 1
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
            
            input   wire    [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    s_data,
            output  reg     [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    m_data
        );
    

    logic   [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    st0_data;
    logic   [S_COMPONENTS-1:0]                      st1_binary;
    logic   [S_COMPONENTS-1:0]                      st2_binary;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage0
            st0_data <= s_data;

            // stage1
            for ( int i = 0; i < S_COMPONENTS; i++ ) begin
                if ( !WRAP_AROUND || param_th1[i] >= param_th0[i] ) begin
                    st1_binary[i] <= ((s_data[i] >= param_th0[i]) && (s_data[i] <= param_th0[i])) ^ param_inv[i];
                end
                else begin
                    st1_binary[i] <= ((s_data[i] <= param_th0[i]) || (s_data[i] >= param_th0[i])) ^ param_inv[i];
                end
            end

            // stage2
            if ( M_COMPONENTS == 1 ) begin
                st2_binary[0] <= param_or ? |st1_binary : &st1_binary;
            end
            else begin
                st2_binary[0] <= st1_binary;
            end

            // stage3
            for ( int i = 0; i < S_COMPONENTS; i++ ) begin
                m_data[i] <= st2_binary[i] ? param_val1[i] : param_val0[i];
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
