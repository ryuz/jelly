// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_img
        #(
            parameter   int                         TUSER_BITS  = 1                 ,
            parameter   int                         WIDTH_BITS  = 10                ,
            parameter   int                         HEIGHT_BITS = 9                 ,
            parameter   int                         BLANK_BITS  = HEIGHT_BITS       ,
            parameter   bit                         CKE_BUFG    = 0            
        )
        (
            input   var logic                       cke,

            input   var logic   [WIDTH_BITS-1:0]    param_width,
            input   var logic   [HEIGHT_BITS-1:0]   param_height,
            input   var logic   [BLANK_BITS-1:0]    param_blank,

            jelly3_axi4s_if.s                       s_axi4s,
            jelly3_axi4s_if.m                       m_axi4s,

            output  var logic                       img_cke,
            jelly3_img_if.m                         m_img,
            jelly3_img_if.s                         s_img
        );
    

    jelly2_axi4s_img_simple
            #(
                .TUSER_WIDTH            (s_axi4s.USER_BITS  ),
                .S_TDATA_WIDTH          (s_axi4s.DATA_BITS  ),
                .M_TDATA_WIDTH          (m_axi4s.DATA_BITS  ),
                .IMG_X_WIDTH            (WIDTH_BITS         ),
                .IMG_Y_WIDTH            (HEIGHT_BITS        ),
                .BLANK_Y_WIDTH          (BLANK_BITS         ),
                .WITH_DE                (m_img.USE_DE       ),
                .WITH_VALID             (m_img.USE_VALID    ),
                .IMG_CKE_BUFG           (CKE_BUFG           )
            )   
        u_axi4s_img_simple  
            (   
                .aresetn                (s_axi4s.aresetn    ),
                .aclk                   (s_axi4s.aclk       ),
                .aclken                 (cke                ),

                .param_img_width        (param_width        ),
                .param_img_height       (param_height       ),
                .param_blank_height     (param_blank        ),


                .s_axi4s_tuser          (s_axi4s.tuser      ),
                .s_axi4s_tlast          (s_axi4s.tlast      ),
                .s_axi4s_tdata          (s_axi4s.tdata      ),
                .s_axi4s_tvalid         (s_axi4s.tvalid     ),
                .s_axi4s_tready         (s_axi4s.tready     ),

                .m_axi4s_tuser          (m_axi4s.tuser      ),
                .m_axi4s_tlast          (m_axi4s.tlast      ),
                .m_axi4s_tdata          (m_axi4s.tdata      ),
                .m_axi4s_tvalid         (m_axi4s.tvalid     ),
                .m_axi4s_tready         (m_axi4s.tready     ),


                .img_cke                (img_cke),

                .m_img_src_row_first    (m_img.row_first    ),
                .m_img_src_row_last     (m_img.row_last     ),
                .m_img_src_col_first    (m_img.col_first    ),
                .m_img_src_col_last     (m_img.col_last     ),
                .m_img_src_de           (m_img.de           ),
                .m_img_src_user         (m_img.user         ),
                .m_img_src_data         (m_img.data         ),
                .m_img_src_valid        (m_img.valid        ),

                .s_img_sink_row_first   (s_img.row_first    ),
                .s_img_sink_row_last    (s_img.row_last     ),
                .s_img_sink_col_first   (s_img.col_first    ),
                .s_img_sink_col_last    (s_img.col_last     ),
                .s_img_sink_de          (s_img.de           ),
                .s_img_sink_user        (s_img.user         ),
                .s_img_sink_data        (s_img.data         ),
                .s_img_sink_valid       (s_img.valid        )
        );
    
    
endmodule


`default_nettype wire


// end of file
