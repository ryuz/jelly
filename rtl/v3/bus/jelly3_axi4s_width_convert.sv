// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_width_convert
        #(
            parameter   bit     M_REG  = 1,
            parameter   bit     S_REG  = 1
        )
        (
            input   var logic       endian      ,
            jelly3_axi4s_if.s       s_axi4s     ,
            jelly3_axi4s_if.m       m_axi4s     
        );
    
    localparam  int     S_NUM       = s_axi4s.STRB_BITS     ;
    localparam  int     M_NUM       = m_axi4s.STRB_BITS     ;
    localparam  int     BYTE_BITS   = s_axi4s.BYTE_BITS     ;
    localparam  type    byte_t      = logic [BYTE_BITS-1:0] ;
    localparam  int     ID_BITS     = s_axi4s.ID_BITS       ;
    localparam  type    id_t        = logic [ID_BITS-1:0]   ;
    localparam  int     DEST_BITS   = s_axi4s.DEST_BITS     ;
    localparam  type    dest_t      = logic [DEST_BITS-1:0] ;
    localparam  int     USER_BITS   = s_axi4s.USER_BITS     ;
    localparam  type    user_t      = logic [USER_BITS-1:0] ;

    initial begin
        if ( s_axi4s.BYTE_BITS != m_axi4s.BYTE_BITS ) begin
            $error("ERROR: s_axi4s.BYTE_BITS != m_axi4s.BYTE_BITS");
        end
        if ( s_axi4s.ID_BITS != m_axi4s.ID_BITS ) begin
            $error("ERROR: s_axi4s.ID_BITS != m_axi4s.ID_BITS");
        end
        if ( s_axi4s.DEST_BITS != m_axi4s.DEST_BITS ) begin
            $error("ERROR: s_axi4s.ID_DEST != m_axi4s.ID_DEST");
        end
        if ( s_axi4s.USER_BITS != m_axi4s.USER_BITS ) begin
            $error("ERROR: s_axi4s.ID_USER != m_axi4s.ID_USER");
        end
        if ( s_axi4s.DATA_BITS != s_axi4s.STRB_BITS * BYTE_BITS ) begin
            $error("ERROR: s_axi4s.DATA_BITS != S_NUM * BYTE_BITS");
        end
        if ( s_axi4s.KEEP_BITS != s_axi4s.STRB_BITS ) begin
            $error("ERROR: s_axi4s.KEEP_BITS != s_axi4s.STRB_BITS");
        end
        if ( m_axi4s.DATA_BITS != m_axi4s.STRB_BITS * BYTE_BITS ) begin
            $error("ERROR: m_axi4s.DATA_BITS != m_axi4s.STRB_BITS * BYTE_BITS");
        end
        if ( m_axi4s.KEEP_BITS != m_axi4s.STRB_BITS ) begin
            $error("ERROR: m_axi4s.KEEP_BITS != m_axi4s.STRB_BITS");
        end
    end

    typedef struct packed {
        id_t    id  ;
        dest_t  dest;
        user_t  user;
    } header_t;

    jelly3_stream_width_convert
            #(
                .UNIT_BITS          ($bits(byte_t)          ),
                .unit_t             (byte_t                 ),
                .S_NUM              (S_NUM                  ),
                .M_NUM              (M_NUM                  ),
                .USE_FIRST          (0                      ),   // first を備える
                .USE_LAST           (s_axi4s.USE_LAST       ),   // last を備える
                .USE_STRB           (s_axi4s.USE_STRB       ),   // strb を備える
                .USE_KEEP           (s_axi4s.USE_KEEP       ),   // keep を備える
                .AUTO_FIRST         (0                      ),   // last の次を自動的に first とする
                .USE_ALIGN_S        (0                      ),   // slave 側のアライメントを指定する
                .USE_ALIGN_M        (0                      ),   // master 側のアライメントを指定する
                .FIRST_OVERWRITE    (0                      ),   // first時前方に残変換があれば吐き出さずに上書き
                .FIRST_FORCE_LAST   (1                      ),   // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
                .REDUCE_KEEP        (0                      ),
                .USER_F_BITS        ($bits(header_t)        ),
                .user_f_t           (header_t               ),
                .S_REG              (1                      ),
                .M_REG              (1                      )
            )
        u_stream_width_convert
            (
                .reset              (~s_axi4s.aresetn       ),
                .clk                (s_axi4s.aclk           ),
                .cke                (s_axi4s.aclken         ),

                .endian             (endian                 ),
                .padding            ('0                     ),
                
                .s_align_s          ('0                     ),
                .s_align_m          ('0                     ),
                .s_first            (1'b0                   ),
                .s_last             (s_axi4s.tlast          ),
                .s_data             (s_axi4s.tdata          ),
                .s_strb             (s_axi4s.tstrb          ),
                .s_keep             (s_axi4s.tkeep          ),
                .s_user_f           ('{
                                        s_axi4s.tid,
                                        s_axi4s.tdest,
                                        s_axi4s.tuser
                                    }),
                .s_user_l           ('0),
                .s_valid            (s_axi4s.tvalid         ),
                .s_ready            (s_axi4s.tready         ),

                .m_first            (                       ),
                .m_last             (m_axi4s.tlast          ),
                .m_data             (m_axi4s.tdata          ),
                .m_strb             (m_axi4s.tstrb          ),
                .m_keep             (m_axi4s.tkeep          ),
                .m_user_f           ('{
                                        m_axi4s.tid,
                                        m_axi4s.tdest,
                                        m_axi4s.tuser
                                    }),
                .m_user_l           (                       ),
                .m_valid            (m_axi4s.tvalid         ),
                .m_ready            (m_axi4s.tready         )
            );
    
endmodule

`default_nettype wire

// end of file
