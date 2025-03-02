// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module image_processing
        #(
            parameter   int     TAPS        = 1                         ,
            parameter   int     DATA_BITS   = 10                        ,
            parameter   int     WIDTH_BITS  = 10                        ,
            parameter   int     HEIGHT_BITS = 9                         ,
            parameter   type    width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   type    height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter           DEVICE      = "RTL"                     
        )
        (
            input   var logic           in_update_req   ,
            input   var width_t         param_width     ,
            input   var height_t        param_height    ,

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s         

//          jelly3_axi4l_if.s           s_axi4l         
        );


    // ----------------------------------------
    //  local patrameter
    // ----------------------------------------

    localparam  int     ROWS_BITS  = $bits(height_t);
    localparam  int     COLS_BITS  = $bits(width_t);
    localparam  type    rows_t     = logic [ROWS_BITS-1:0];
    localparam  type    cols_t     = logic [COLS_BITS-1:0];

    localparam  int     S_CH_BITS  = s_axi4s.DATA_BITS;
    localparam  int     M_CH_BITS  = m_axi4s.DATA_BITS;


    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------
    /*
    localparam DEC_WB    = 0;
    localparam DEC_DEMOS = 1;
    localparam DEC_NUM   = 2;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (s_axi4l.ADDR_BITS  ),
                .DATA_BITS      (s_axi4l.DATA_BITS  )
            )
        axi4l_dec [DEC_NUM]
            (
                .aresetn        (s_axi4l.aresetn    ),
                .aclk           (s_axi4l.aclk       ),
                .aclken         (s_axi4l.aclken     )
            );
    
    // address map
    assign {axi4l_dec[DEC_WB   ].addr_base, axi4l_dec[DEC_WB   ].addr_high} = {40'ha012_1000, 40'ha012_1fff};
    assign {axi4l_dec[DEC_DEMOS].addr_base, axi4l_dec[DEC_DEMOS].addr_high} = {40'ha012_2000, 40'ha012_2fff};

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (DEC_NUM    ),
                .DEC_ADDR_BITS  (16         )
            )
        u_axi4l_addr_decoder
            (
                .s_axi4l        (s_axi4l    ),
                .m_axi4l        (axi4l_dec  )
            );
    */

    // -------------------------------------
    //  AXI4-Stream <=> Image Interface
    // -------------------------------------

    logic           reset ;
    logic           clk   ;
    logic           cke   ;
    assign  reset = ~s_axi4s.aresetn;
    assign  clk   = s_axi4s.aclk;
    
    jelly3_mat_if
            #(
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (S_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_src
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
            );

   jelly3_mat_if
            #(
                .TAPS       (TAPS           ),
                .ROWS_BITS  ($bits(rows_t)  ),
                .COLS_BITS  ($bits(cols_t)  ),
                .CH_BITS    (M_CH_BITS      ),
                .CH_DEPTH   (1              )
            )
        img_sink
            (
                .reset      (reset          ),
                .clk        (clk            ),
                .cke        (cke            )
            );
    
    jelly3_axi4s_mat
            #(
                .ROWS_BITS      ($bits(rows_t)      ),
                .COLS_BITS      ($bits(cols_t)      ),
                .BLANK_BITS     (4                  ),
                .CKE_BUFG       (0                  )
            )
        u_axi4s_mat
            (
                .param_rows     (param_height       ),
                .param_cols     (param_width        ),
                .param_blank    (4'd5               ),
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (m_axi4s            ),

                .img_cke        (cke                ),
                .m_mat          (img_src.m          ),
                .s_mat          (img_sink.s         )
        );
    
    
    assign img_sink.row_first   = img_src.row_first;
    assign img_sink.row_last    = img_src.row_last ;
    assign img_sink.col_first   = img_src.col_first;
    assign img_sink.col_last    = img_src.col_last ;
    assign img_sink.de          = img_src.de       ;
    assign img_sink.data        = img_src.data     ;
    assign img_sink.user        = img_src.user     ;
    assign img_sink.valid       = img_src.valid    ;
    

    // -------------------------------------
    //  frame buffer
    // -------------------------------------

    jelly3_mat_if
            #(
                .CH_BITS    (S_CH_BITS  ),
                .CH_DEPTH   (2          )
            )
        img_buf
            (
                .reset      (reset      ),
                .clk        (clk        ),
                .cke        (cke        )
            );

    jelly3_mat_buf_mem
            #(
                .N              (2          ),
                .BUF_SIZE       (640 * 132  ),
                .SDP            (1          ),
                .RAM_TYPE       ("ultra"    ),
                .DOUT_REG       (1          )
            )
        u_mat_buf_mem
            (
                .s_mat          (img_src    ),
                .m_mat          (img_buf    )
            );


endmodule



`default_nettype wire



// end of file
