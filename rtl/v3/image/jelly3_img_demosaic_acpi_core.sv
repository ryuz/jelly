// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_core
        #(
            parameter   int     CH_BITS          = 10                       ,
            parameter   type    ch_t             = logic [CH_BITS-1:0]      ,
            parameter   int     MAX_COLS         = 4096                     ,
            parameter           RAM_TYPE         = "block"                  ,
            parameter   bit     RGB_SWAP         = 0                        ,
            parameter   bit     BYPASS_SIZE      = 1'b1                     ,
            localparam  type    phase_t          = logic [1:0]              
        )
        (
            input   var phase_t     param_phase,
            jelly3_mat_if.s         s_img,
            jelly3_mat_if.m         m_img
        );
    
    localparam  int     TAPS      = s_img.TAPS      ;
    localparam  int     USER_BITS = s_img.USER_BITS ;
    localparam  type    user_t    = logic   [USER_BITS-1:0];
    
    // G
    jelly3_mat_if
            #(
                .TAPS           (TAPS           ),
                .CH_BITS        ($bits(ch_t)    ),
                .CH_DEPTH       (2              ),
                .USER_BITS      ($bits(user_t)  )
            )
         img_g
            (
                .reset          (s_img.reset    ),
                .clk            (s_img.clk      ),
                .cke            (s_img.cke      )
            );
    
    jelly3_img_demosaic_acpi_g_core
            #(
                .CH_BITS        ($bits(ch_t)    ),
                .ch_t           (ch_t           ),
                .MAX_COLS       (MAX_COLS       ),
                .RAM_TYPE       (RAM_TYPE       ),
                .BYPASS_SIZE    (BYPASS_SIZE    )
            )
        u_img_demosaic_acpi_g_core
            (
                .param_phase    (param_phase    ),
                .s_img          (s_img          ),
                .m_img          (img_g.m        )
            );
    
    
    // R,B
    jelly3_img_demosaic_acpi_rb_core
            #(
                .CH_BITS        ($bits(ch_t)    ),
                .ch_t           (ch_t           ),
                .MAX_COLS       (MAX_COLS       ),
                .RAM_TYPE       (RAM_TYPE       ),
                .BYPASS_SIZE    (BYPASS_SIZE    ),
                .RGB_SWAP       (RGB_SWAP       )
            )
        u_img_demosaic_acpi_rb_core
            (
                .param_phase    (param_phase    ),
                .s_img          (img_g.s        ),
                .m_img          (m_img          )
            );
    
    // assertion
    initial begin
        sva_data_bits   : assert ( $bits(ch_t) == s_img.DATA_BITS ) else $warning("$bits(ch_t) != s_img.DATA_BITS");
        sva_m_data_bits : assert ( m_img.DATA_BITS == s_img.DATA_BITS * 4) else $warning("m_img.DATA_BITS != s_img.DATA_BITS * 4");
    end
    always_comb begin
        sva_connect_reset : assert (m_img.reset === s_img.reset);
        sva_connect_clk   : assert (m_img.clk   === s_img.clk  );
        sva_connect_cke   : assert (m_img.cke   === s_img.cke  );
    end

endmodule


`default_nettype wire


// end of file
