// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_mat
        #(
            parameter   int     ROWS_BITS   = 9                         ,
            parameter   type    rows_t      = logic [ROWS_BITS-1:0]     ,
            parameter   int     COLS_BITS   = 10                        ,
            parameter   type    cols_t      = logic [COLS_BITS-1:0]     ,
            parameter   int     BLANK_BITS  = ROWS_BITS                 ,
            parameter   type    blank_t     = logic [BLANK_BITS-1:0]    ,
            parameter   bit     CKE_BUFG    = 0                         
        )
        (
            input   var rows_t      param_rows      ,
            input   var cols_t      param_cols      ,
            input   var blank_t     param_blank     ,

            jelly3_axi4s_if.s       s_axi4s         ,
            jelly3_axi4s_if.m       m_axi4s         ,

            output  var logic       out_cke         ,
            jelly3_mat_if.m         m_mat           ,
            jelly3_mat_if.s         s_mat           
        );
    

    jelly2_axi4s_img_simple
            #(
                .TUSER_WIDTH            (s_axi4s.USER_BITS  ),
                .S_TDATA_WIDTH          (s_axi4s.DATA_BITS  ),
                .M_TDATA_WIDTH          (m_axi4s.DATA_BITS  ),
                .IMG_X_WIDTH            ($bits(cols_t)      ),
                .IMG_Y_WIDTH            ($bits(rows_t)      ),
                .BLANK_Y_WIDTH          ($bits(blank_t)     ),
                .WITH_DE                (m_mat.USE_DE       ),
                .WITH_VALID             (m_mat.USE_VALID    ),
                .IMG_CKE_BUFG           (CKE_BUFG           )
            )
        u_axi4s_img_simple
            (
                .aresetn                (s_axi4s.aresetn    ),
                .aclk                   (s_axi4s.aclk       ),
                .aclken                 (s_axi4s.aclken     ),

                .param_img_width        (param_cols         ),
                .param_img_height       (param_rows         ),
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


                .img_cke                (out_cke            ),

                .m_img_src_row_first    (m_mat.row_first    ),
                .m_img_src_row_last     (m_mat.row_last     ),
                .m_img_src_col_first    (m_mat.col_first    ),
                .m_img_src_col_last     (m_mat.col_last     ),
                .m_img_src_de           (m_mat.de           ),
                .m_img_src_user         (m_mat.user         ),
                .m_img_src_data         (m_mat.data         ),
                .m_img_src_valid        (m_mat.valid        ),

                .s_img_sink_row_first   (s_mat.row_first    ),
                .s_img_sink_row_last    (s_mat.row_last     ),
                .s_img_sink_col_first   (s_mat.col_first    ),
                .s_img_sink_col_last    (s_mat.col_last     ),
                .s_img_sink_de          (s_mat.de           ),
                .s_img_sink_user        (s_mat.user         ),
                .s_img_sink_data        (s_mat.data         ),
                .s_img_sink_valid       (s_mat.valid        )
        );
    
    assign m_mat.rows = param_rows;
    assign m_mat.cols = param_cols;
    
endmodule


`default_nettype wire


// end of file
