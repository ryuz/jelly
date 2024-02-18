// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_demosaic_acpi_core
        #(
            parameter   int             DATA_BITS        = 10                       ,
            parameter   type            data_t           = logic [DATA_BITS-1:0]    ,
            parameter   int             MAX_COLS         = 4096                     ,
            parameter                   RAM_TYPE         = "block"                  ,
            localparam  type            phase_t          = logic [1:0]              
        )
        (
            input   var phase_t     param_phase,
            jelly3_img_if.s         s_img,
            jelly3_img_if.m         m_img
        );
    
    localparam  int     USER_BITS = s_img.USER_BITS;
    localparam  type    user_t    = logic   [USER_BITS-1:0];
    
    // G
    jelly3_img_if
            #(
                .DATA_BITS      ($bits(data_t)*2),
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
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .MAX_COLS       (MAX_COLS   ),
                .RAM_TYPE       (RAM_TYPE   )
            )
        u_img_demosaic_acpi_g_core
            (
                .param_phase    (param_phase),
                .s_img          (s_img),
                .m_img          (img_g.m)
            );
    
    
    // R,B
    jelly3_img_if
            #(
                .DATA_BITS      ($bits(data_t)*2),
                .USER_BITS      ($bits(user_t)  )
            )
         img_rb
            (
                .reset          (s_img.reset    ),
                .clk            (s_img.clk      ),
                .cke            (s_img.cke      )
            );

    jelly3_img_demosaic_acpi_rb_core
            #(
                .DATA_BITS      ($bits(data_t)*2)
            )
        u_img_demosaic_acpi_rb_core
            (
                .param_phase    (param_phase    ),
                .s_img          (img_g.s        ),
                .m_img          (m_img          )
            );
    
    
endmodule


`default_nettype wire


// end of file
