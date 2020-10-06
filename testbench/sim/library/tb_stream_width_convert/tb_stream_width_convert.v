
`timescale 1ns / 1ps
`default_nettype none


module tb_stream_width_convert();
    localparam RATE    = 10.0;
    
    initial begin
        $dumpfile("tb_stream_width_convert.vcd");
        $dumpvars(0, tb_stream_width_convert);
        #10000
        $finish();
    end
    
    parameter   BUSY = 0;
    
    reg     reset = 1'b1;
    always #(RATE*100)      reset = 1'b0;
    
    reg     clk = 1'b1;
    always #(RATE/2.0)      clk = ~clk;
    
    reg     cke = 1;
    always @(posedge clk)   cke <= BUSY ? {$random} : 1'b1;
    
    
    parameter UNIT_WIDTH          = 8;
    parameter S_NUM               = 2;
    parameter M_NUM               = 5;
    parameter HAS_FIRST           = 1;                          // first を備える
    parameter HAS_LAST            = 1;                          // last を備える
    parameter HAS_STRB            = 0;                          // strb を備える
    parameter HAS_KEEP            = 0;                          // keep を備える
    parameter HAS_ALIGN_S         = 1;                          // slave 側のアライメントを指定する
    parameter HAS_ALIGN_M         = 1;                          // master 側のアライメントを指定する
    parameter AUTO_FIRST          = !HAS_FIRST;                 // last の次を自動的に first とする
    parameter FIRST_OVERWRITE     = 0;  // first時前方に残変換があれば吐き出さずに上書き
    parameter FIRST_FORCE_LAST    = 0;  // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
    parameter ALIGN_S_WIDTH       = S_NUM <=   2 ? 1 :
                                    S_NUM <=   4 ? 2 :
                                    S_NUM <=   8 ? 3 :
                                    S_NUM <=  16 ? 4 :
                                    S_NUM <=  32 ? 5 :
                                    S_NUM <=  64 ? 6 :
                                    S_NUM <= 128 ? 7 :
                                    S_NUM <= 256 ? 8 :
                                    S_NUM <= 512 ? 9 : 10;
    parameter ALIGN_M_WIDTH       = M_NUM <=   2 ? 1 :
                                    M_NUM <=   4 ? 2 :
                                    M_NUM <=   8 ? 3 :
                                    M_NUM <=  16 ? 4 :
                                    M_NUM <=  32 ? 5 :
                                    M_NUM <=  64 ? 6 :
                                    M_NUM <= 128 ? 7 :
                                    M_NUM <= 256 ? 8 :
                                    M_NUM <= 512 ? 9 : 10;
    parameter USER_F_WIDTH        = 8;
    parameter USER_L_WIDTH        = 8;
    parameter S_REGS              = 1;
    parameter M_REGS              = 1;
    
    // local
    parameter S_DATA_WIDTH        = S_NUM*UNIT_WIDTH;
    parameter M_DATA_WIDTH        = M_NUM*UNIT_WIDTH;
    parameter USER_F_BITS         = USER_F_WIDTH > 0 ? USER_F_WIDTH : 1;
    parameter USER_L_BITS         = USER_L_WIDTH > 0 ? USER_L_WIDTH : 1;
    
    
    reg                             endian  = 1;
    reg     [UNIT_WIDTH-1:0]        padding = 32'hxxxx_xxxx; // 32'h55aa5a5a;
    
    reg     [31:0]                  count;
    
    wire    [ALIGN_S_WIDTH-1:0]     s_align_s = 0;
    wire    [ALIGN_M_WIDTH-1:0]     s_align_m = 2;
    wire                            s_first = (count[2:0] == 3'b000);
    wire                            s_last  = (count[2:0] == 3'b111);
    reg     [S_DATA_WIDTH-1:0]      s_data;
    reg     [S_NUM-1:0]             s_strb = {S_NUM{1'b1}};
    reg     [S_NUM-1:0]             s_keep = {S_NUM{1'b1}};
    reg     [USER_F_BITS-1:0]       s_user_f = 8'hff;
    reg     [USER_L_BITS-1:0]       s_user_l = 8'hff;
    reg                             s_valid;
    wire                            s_ready;
    
    wire                            m_first;
    wire                            m_last;
    wire    [M_DATA_WIDTH-1:0]      m_data;
    wire    [M_NUM-1:0]             m_strb;
    wire    [M_NUM-1:0]             m_keep;
    wire    [USER_F_BITS-1:0]       m_user_f;
    wire    [USER_L_BITS-1:0]       m_user_l;
    wire                            m_valid;
    reg                             m_ready = 1;
    
    integer                         i;
    
    always @(posedge clk) begin
        if ( reset ) begin
            count   <= 0;
            for ( i = 0; i < S_NUM; i = i+1 ) begin
                s_data[i*UNIT_WIDTH +: UNIT_WIDTH] <= endian ? S_NUM - 1 - i : i;
            end
            s_user_f = 0;
            s_user_l = 16;
            s_valid <= 0;
        end
        else if ( cke ) begin
            if ( s_valid && s_ready ) begin
                for ( i = 0; i < S_NUM; i = i+1 ) begin
                    s_data[i*UNIT_WIDTH +: UNIT_WIDTH] <= s_data[i*UNIT_WIDTH +: UNIT_WIDTH] + S_NUM;
                end
                s_user_f <= s_user_f + 1;
                s_user_l <= s_user_l + 1;
                count <= count + 1;
            end
            
            if ( !s_valid || s_ready ) begin
                s_valid <= BUSY ? {$random()} : 1'b1;
            end
        end
    end
    
    always @(posedge clk) begin
        m_ready <= BUSY ? {$random()} : 1'b1;
    end
    
    
    jelly_stream_width_convert
            #(
                .UNIT_WIDTH         (UNIT_WIDTH),
                .S_NUM              (S_NUM),
                .M_NUM              (M_NUM),
                .HAS_FIRST          (HAS_FIRST),
                .HAS_LAST           (HAS_LAST),
                .HAS_STRB           (HAS_STRB),
                .HAS_KEEP           (HAS_KEEP),
                .AUTO_FIRST         (AUTO_FIRST),
                .HAS_ALIGN_S        (HAS_ALIGN_S),
                .HAS_ALIGN_M        (HAS_ALIGN_M),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                .ALIGN_S_WIDTH      (ALIGN_S_WIDTH),
                .ALIGN_M_WIDTH      (ALIGN_M_WIDTH),
                .USER_F_WIDTH       (USER_F_WIDTH),
                .USER_L_WIDTH       (USER_L_WIDTH),
                .S_REGS             (S_REGS),
                .M_REGS             (M_REGS)
            )
        i_stream_width_convert
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .endian             (endian),
                .padding            (padding),
                
                .s_align_s          (s_align_s),
                .s_align_m          (s_align_m),
                .s_first            (s_first),
                .s_last             (s_last),
                .s_data             (s_data),
                .s_strb             (s_strb),
                .s_keep             (s_keep),
                .s_user_f           (s_user_f),
                .s_user_l           (s_user_l),
                .s_valid            (s_valid),
                .s_ready            (s_ready),
                
                .m_first            (m_first),
                .m_last             (m_last),
                .m_data             (m_data),
                .m_strb             (m_strb),
                .m_keep             (m_keep),
                .m_user_f           (m_user_f),
                .m_user_l           (m_user_l),
                .m_valid            (m_valid),
                .m_ready            (m_ready)
            );
    
    integer fp;
    initial begin
        fp = $fopen("out.txt", "w");
    end
    
    always @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %h %h %b %b", m_data, m_user_f, m_user_l, m_first, m_last);
            end
        end
    end
    
    
    
endmodule


`default_nettype wire


// end of file
