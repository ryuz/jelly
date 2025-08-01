`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
   
    parameter   int     UNIT_BITS        = 8                                    ;
    parameter   type    unit_t           = logic [UNIT_BITS-1:0]                ;
    parameter   int     S_NUM            = 5                                    ;
    parameter   int     M_NUM            = 3                                    ;
    parameter   bit     USE_FIRST        = 0                                    ;   // first を備える
    parameter   bit     USE_LAST         = 0                                    ;   // last を備える
    parameter   bit     USE_STRB         = 0                                    ;   // strb を備える
    parameter   bit     USE_KEEP         = 0                                    ;   // keep を備える
    parameter   bit     AUTO_FIRST       = !USE_FIRST                           ;   // last の次を自動的に first とする
    parameter   bit     USE_ALIGN_S      = 0                                    ;   // slave 側のアライメントを指定する
    parameter   bit     USE_ALIGN_M      = 0                                    ;   // master 側のアライメントを指定する
    parameter   bit     FIRST_OVERWRITE  = 0                                    ;   // first時前方に残変換があれば吐き出さずに上書き
    parameter   bit     FIRST_FORCE_LAST = 1                                    ;   // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
    parameter   bit     REDUCE_KEEP      = 0                                    ;
    parameter   int     ALIGN_S_BITS     = $clog2(S_NUM) > 0 ? $clog2(S_NUM) : 1;
    parameter   type    align_s_t        = logic [ALIGN_S_BITS-1:0]             ;
    parameter   int     ALIGN_M_BITS     = $clog2(M_NUM) > 0 ? $clog2(M_NUM) : 1;
    parameter   type    align_m_t        = logic [ALIGN_M_BITS-1:0]             ;
    parameter   int     USER_F_BITS      = 1                                    ;
    parameter   type    user_f_t         = logic [USER_F_BITS-1:0]              ;
    parameter   int     USER_L_BITS      = 1                                    ;
    parameter   type    user_l_t         = logic [USER_L_BITS-1:0]              ;
    parameter   bit     S_REG            = 1                                    ;
    parameter   bit     M_REG            = 1                                    ;

    logic                   cke          = 1'b1;
    logic                   endian      ;
    unit_t                  padding     ;
    align_s_t               s_align_s   ;
    align_m_t               s_align_m   ;
    logic                   s_first     ;   // アライメント先頭
    logic                   s_last      ;   // アライメント末尾
    unit_t  [S_NUM-1:0]     s_data      ;
    logic   [S_NUM-1:0]     s_strb      ;
    logic   [S_NUM-1:0]     s_keep      ;
    user_f_t                s_user_f    ;   // アライメント先頭前提で伝搬するユーザーデータ
    user_l_t                s_user_l    ;   // アライメント末尾前提で伝搬するユーザーデータ
    logic                   s_valid     ;
    logic                   s_ready     ;

    logic                   m_first     ;
    logic                   m_last      ;
    unit_t [M_NUM-1:0]      m_data      ;
    logic  [M_NUM-1:0]      m_strb      ;
    logic  [M_NUM-1:0]      m_keep      ;
    user_f_t                m_user_f    ;
    user_l_t                m_user_l    ;
    logic                   m_valid     ;
    logic                   m_ready     ;
    
    jelly3_stream_width_convert
            #(
                .UNIT_BITS          (UNIT_BITS          ),
                .unit_t             (unit_t             ),
                .S_NUM              (S_NUM              ),
                .M_NUM              (M_NUM              ),
                .USE_FIRST          (USE_FIRST          ),
                .USE_LAST           (USE_LAST           ),
                .USE_STRB           (USE_STRB           ),
                .USE_KEEP           (USE_KEEP           ),
                .AUTO_FIRST         (AUTO_FIRST         ),
                .USE_ALIGN_S        (USE_ALIGN_S        ),
                .USE_ALIGN_M        (USE_ALIGN_M        ),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE    ),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST   ),
                .REDUCE_KEEP        (REDUCE_KEEP        ),
                .ALIGN_S_BITS       (ALIGN_S_BITS       ),
                .align_s_t          (align_s_t          ),
                .ALIGN_M_BITS       (ALIGN_M_BITS       ),
                .align_m_t          (align_m_t          ),
                .USER_F_BITS        (USER_F_BITS        ),
                .user_f_t           (user_f_t           ),
                .USER_L_BITS        (USER_L_BITS        ),
                .user_l_t           (user_l_t           ),
                .S_REG              (S_REG              ),
                .M_REG              (M_REG              )
            )
        u_stream_width_convert
            (
                .reset          ,
                .clk            ,
                .cke            ,
                .endian         ,
                .padding        ,
                .s_align_s      ,
                .s_align_m      ,
                .s_first        ,
                .s_last         ,
                .s_data         ,
                .s_strb         ,
                .s_keep         ,
                .s_user_f       ,
                .s_user_l       ,
                .s_valid        ,
                .s_ready        ,
                .m_first        ,
                .m_last         ,
                .m_data         ,
                .m_strb         ,
                .m_keep         ,
                .m_user_f       ,
                .m_user_l       ,
                .m_valid        ,
                .m_ready        
            );


    logic                   s2_ready     ;
    logic                   m2_first     ;
    logic                   m2_last      ;
    unit_t [M_NUM-1:0]      m2_data      ;
    logic  [M_NUM-1:0]      m2_strb      ;
    logic  [M_NUM-1:0]      m2_keep      ;
    user_f_t                m2_user_f    ;
    user_l_t                m2_user_l    ;
    logic                   m2_valid     ;
    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (UNIT_BITS          ),
                .S_NUM              (S_NUM              ),
                .M_NUM              (M_NUM              ),
                .HAS_FIRST          (USE_FIRST          ),
                .HAS_LAST           (USE_LAST           ),
                .HAS_STRB           (USE_STRB           ),
                .HAS_KEEP           (USE_KEEP           ),
                .AUTO_FIRST         (AUTO_FIRST         ),
                .HAS_ALIGN_S        (USE_ALIGN_S        ),
                .HAS_ALIGN_M        (USE_ALIGN_M        ),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE    ),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST   ),
                .REDUCE_KEEP        (REDUCE_KEEP        ),
                .ALIGN_S_WIDTH      (ALIGN_S_BITS       ),
                .ALIGN_M_WIDTH      (ALIGN_M_BITS       ),
                .USER_F_WIDTH       (USER_F_BITS        ),
                .USER_L_WIDTH       (USER_L_BITS        ),
                .S_REGS             (S_REG              ),
                .M_REGS             (M_REG              )
            )
        u_stream_width_convert2
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),
                .endian             (endian             ),
                .padding            (padding            ),
                .s_align_s          (s_align_s          ),
                .s_align_m          (s_align_m          ),
                .s_first            (s_first            ),
                .s_last             (s_last             ),
                .s_data             (s_data             ),
                .s_strb             (s_strb             ),
                .s_keep             (s_keep             ),
                .s_user_f           (s_user_f           ),
                .s_user_l           (s_user_l           ),
                .s_valid            (s_valid            ),
                .s_ready            (s2_ready           ),
                .m_first            (m2_first           ),
                .m_last             (m2_last            ),
                .m_data             (m2_data            ),
                .m_strb             (m2_strb            ),
                .m_keep             (m2_keep            ),
                .m_user_f           (m2_user_f          ),
                .m_user_l           (m2_user_l          ),
                .m_valid            (m2_valid           ),
                .m_ready            (m_ready            )
            );

    // master
    always_ff @(posedge clk) begin
        if ( reset ) begin
            endian     <= '0;
            padding    <= '0;
            s_align_s  <= '0;
            s_align_m  <= '0;
            s_first    <= '0;   // アライメント先頭
            s_last     <= '0;   // アライメント末尾
            s_data     <= '0;
            s_strb     <= '1;
            s_keep     <= '1;
            s_user_f   <= '0;   // アライメント先頭前提で伝搬するユーザーデータ
            s_user_l   <= '0;   // アライメント末尾前提で伝搬するユーザーデータ
            s_valid    <= '0;
        end
        else begin
            if ( !(s_valid && !s_ready) ) begin
                s_strb     <= S_NUM'($random);
                s_keep     <= S_NUM'($random);
                s_valid <= 1'($random);
            end
            
            if ( s_valid && s_ready ) begin
                s_data <= s_data + 1'b1;
            end
        end
    end


    
    logic                       reg_ready;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_ready                <= 1'b0;
        end
        else begin
            if ( m_valid && m_ready ) begin
                if ( m_data != m2_data ) begin
                    $display("m_data mismatch: %0h != %0h", m_data, m2_data);
                end
                if ( m_strb != m2_strb ) begin
                    $display("m_strb mismatch: %0h != %0h", m_data, m2_data);
                end
                if ( m_keep != m2_keep ) begin
                    $display("m_keep mismatch: %0h != %0h", m_data, m2_data);
                end
            end
            m_ready <= 1'($random);
        end
    end
    
endmodule


`default_nettype wire


// end of file
