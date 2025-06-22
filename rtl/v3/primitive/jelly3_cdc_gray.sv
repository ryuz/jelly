// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_cdc_gray
        #(
            parameter   DEST_SYNC_FF          = 4           ,
            parameter   SIM_ASSERT_CHK        = 0           ,
            parameter   SIM_LOSSLESS_GRAY_CHK = 0           ,
            parameter   WIDTH                 = 2           ,
            parameter   DEVICE                = "RTL"       ,
            parameter   SIMULATION            = "false"     ,
            parameter   DEBUG                 = "false"     
        )
        (
            input   var logic               src_clk     ,
            input   var logic   [WIDTH-1:0] src_in_bin  ,
            input   var logic               dest_clk    ,
            output  var logic   [WIDTH-1:0] dest_out_bin
        );

    if (   string'(DEVICE) == "SPARTAN6"
        || string'(DEVICE) == "VIRTEX6"
        || string'(DEVICE) == "7SERIES"
        || string'(DEVICE) == "ULTRASCALE"
        || string'(DEVICE) == "ULTRASCALE_PLUS"
        || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
        || string'(DEVICE) == "ULTRASCALE_PLUS_ES2"
        || string'(DEVICE) == "VERSAL_AI_CORE"
        || string'(DEVICE) == "VERSAL_AI_CORE_ES1"
        || string'(DEVICE) == "VERSAL_AI_CORE_ES2"
        || string'(DEVICE) == "VERSAL_PRIME"
        || string'(DEVICE) == "VERSAL_PRIME_ES1"
        || string'(DEVICE) == "VERSAL_PRIME_ES2"
    ) begin : xilinx
        xpm_cdc_gray
                #(
                    .DEST_SYNC_FF           (DEST_SYNC_FF           ),
                    .SIM_ASSERT_CHK         (SIM_ASSERT_CHK         ),
                    .SIM_LOSSLESS_GRAY_CHK  (SIM_LOSSLESS_GRAY_CHK  ),
                    .WIDTH                  (WIDTH                  ) 
                )
            u_xpm_cdc_gray
                (
                    .src_clk                (src_clk                ),
                    .src_in_bin             (src_in_bin             ),
                    .dest_clk               (dest_clk               ),
                    .dest_out_bin           (dest_out_bin           )
                );
    end
    else begin : rtl
        function automatic [WIDTH-1:0] binary_to_graycode(input [WIDTH-1:0] binary);
            automatic logic [WIDTH-1:0]   graycode;
            graycode[WIDTH-1] = binary[WIDTH-1];
            for ( int i = WIDTH - 2; i >= 0; i-- ) begin
                graycode[i] = binary[i+1] ^ binary[i];
            end
            return graycode;
        endfunction

        function automatic [WIDTH-1:0] graycode_to_binary(input [WIDTH-1:0] graycode);
            automatic logic [WIDTH-1:0]   binary;
            binary[WIDTH-1] = graycode[WIDTH-1];
            for ( int i = WIDTH - 2; i >= 0; i-- ) begin
                binary[i] = binary[i+1] ^ graycode[i];
            end
            return binary;
        endfunction

        logic   [WIDTH-1:0] src_graycode;
        logic   [WIDTH-1:0] dest_graycode;
        jelly3_cdc_array_single
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (1'b1           ),
                    .WIDTH          (WIDTH          ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_array_single
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_graycode   ),
                    .dest_clk       (dest_clk       ),
                    .dest_out       (dest_graycode  )
                );
        assign src_graycode = binary_to_graycode(src_in_bin);
        assign dest_out_bin = graycode_to_binary(dest_graycode);
    end

endmodule


`default_nettype wire


// end of file
