// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_fifo
        #(
            parameter   bit     ASYNC       = 1,
            parameter   int     PTR_BITS    = 9,
            parameter           RAM_TYPE    = "block",
            parameter   bit     LOW_DEALY   = 0,
            parameter   bit     DOUT_REGS   = 1,
            parameter   bit     S_REGS      = 1,
            parameter   bit     M_REGS      = 1
        )
        (
            jelly3_axi4s_if.s                   s_axi4s     ,
            jelly3_axi4s_if.m                   m_axi4s     ,
            output  var logic   [PTR_BITS:0]    s_free_count,
            output  var logic   [PTR_BITS:0]    m_data_count
        );
    
    jelly2_axi4s_fifo
            #(
                .ASYNC          (ASYNC              ),
                .HAS_FIRST      (1'b0               ),
                .HAS_LAST       (s_axi4s.USE_LAST   ),
                .HAS_STRB       (s_axi4s.USE_STRB   ),
                .HAS_KEEP       (s_axi4s.USE_KEEP   ),
                .BYTE_WIDTH     (s_axi4s.BYTE_BITS  ),
                .TDATA_WIDTH    (s_axi4s.DATA_BITS  ),
                .TSTRB_WIDTH    (s_axi4s.STRB_BITS  ),
                .TKEEP_WIDTH    (s_axi4s.KEEP_BITS  ),
                .TUSER_WIDTH    (s_axi4s.USER_BITS  ),
                .PTR_WIDTH      (PTR_BITS           ),
                .RAM_TYPE       (RAM_TYPE           ),
                .LOW_DEALY      (LOW_DEALY          ),
                .DOUT_REGS      (DOUT_REGS          ),
                .S_REGS         (S_REGS             ),
                .M_REGS         (M_REGS             )
            )
        u_axi4s_fifo
            (
                .s_aresetn      (s_axi4s.aresetn    ),
                .s_aclk         (s_axi4s.aclk       ),
                .s_axi4s_tdata  (s_axi4s.tdata      ),
                .s_axi4s_tstrb  (s_axi4s.tstrb      ),
                .s_axi4s_tkeep  (s_axi4s.tkeep      ),
                .s_axi4s_tfirst ('0                 ),
                .s_axi4s_tlast  (s_axi4s.tlast      ),
                .s_axi4s_tuser  (s_axi4s.tuser      ),
                .s_axi4s_tvalid (s_axi4s.tvalid     ),
                .s_axi4s_tready (s_axi4s.tready     ),
                .s_free_count,
            
                .m_aresetn      (m_axi4s.aresetn    ),
                .m_aclk         (m_axi4s.aclk       ),
                .m_axi4s_tdata  (m_axi4s.tdata      ),
                .m_axi4s_tstrb  (m_axi4s.tstrb      ),
                .m_axi4s_tkeep  (m_axi4s.tkeep      ),
                .m_axi4s_tfirst (                   ),
                .m_axi4s_tlast  (m_axi4s.tlast      ),
                .m_axi4s_tuser  (m_axi4s.tuser      ),
                .m_axi4s_tvalid (m_axi4s.tvalid     ),
                .m_axi4s_tready (m_axi4s.tready     ),
                .m_data_count
            );

endmodule


`default_nettype wire


// end of file

