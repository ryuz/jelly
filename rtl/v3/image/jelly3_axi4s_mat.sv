// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
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
            parameter   bit     CKE_BUFG    = 0                         ,
            parameter           DEVICE      = "RTL"                     ,
            parameter           SIMULATION  = "false"                   ,
            parameter           DEBUG       = "false"                   
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

    
    logic   almost_full;

    // axi4s_to_mat
    jelly3_axi4s_to_mat
            #(
                .ROWS_BITS      (ROWS_BITS          ),
                .rows_t         (rows_t             ),
                .COLS_BITS      (COLS_BITS          ),
                .cols_t         (cols_t             ),
                .BLANK_BITS     (BLANK_BITS         ),
                .blank_t        (blank_t            ),
                .CKE_BUFG       (CKE_BUFG           )
            )
        u_axi4s_to_mat
            (
                .param_rows     ,
                .param_cols     ,
                .param_blank    ,
                
                .almost_full    (almost_full        ),
                .s_axi4s        (s_axi4s            ),
                
                .out_cke        (out_cke            ),
                .m_mat          (m_mat              )
            );

    // mat_to_axi4s
    jelly3_axi4s_if
            #(
                .USER_BITS      (m_axi4s.USER_BITS  ),
                .DATA_BITS      (m_axi4s.DATA_BITS  )
            )
        axi4s_dst
            (
                .aresetn        (s_axi4s.aresetn    ),
                .aclk           (s_axi4s.aclk       ),
                .aclken         (1'b1               )
            );

    jelly3_mat_to_axi4s
        u_mat_to_axi4s
            (
                .s_mat          (s_mat              ),
                .m_axi4s        (axi4s_dst.m        )
            );


    // output buffer
    logic   [3:0]   buf_free_size;
    jelly3_stream_fifo_sr
            #(
                .PTR_BITS       (3                  ),
                .DATA_BITS      (m_axi4s.USER_BITS + 1 + m_axi4s.DATA_BITS),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_sr
            (
                .reset          (~m_axi4s.aresetn   ),
                .clk            (m_axi4s.aclk       ),
                .cke            (1'b1               ),
                
                .s_data         ({
                                    axi4s_dst.tuser,
                                    axi4s_dst.tlast,
                                    axi4s_dst.tdata
                                }),
                .s_valid        (axi4s_dst.tvalid && axi4s_dst.aclken),
                .s_ready        (axi4s_dst.tready   ),
                .s_free_size    (buf_free_size      ),

                .m_data         ({
                                    m_axi4s.tuser,
                                    m_axi4s.tlast,
                                    m_axi4s.tdata
                                }),
                .m_valid        (m_axi4s.tvalid     ),
                .m_ready        (m_axi4s.tready     ),
                .m_data_size    (                   )
            );

    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            almost_full <= 1'b0;
        end
        else begin
            almost_full <= (buf_free_size < 4);
        end
    end
    
endmodule


`default_nettype wire


// end of file
