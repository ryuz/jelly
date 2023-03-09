

`timescale 1ns / 1ps
`default_nettype none

module rmii_phy
        (
            input   wire                reset,
            input   wire                clk,
            
            output  wire                rmii_txen,
            output  wire    [1:0]       rmii_tx,
            input   wire    [1:0]       rmii_rx,
            input   wire                rmii_crs,
            input   wire                rmii_mdc,
            input   wire                rmii_mdio_i,
            output  wire                rmii_mdio_o,
            output  wire                rmii_mdio_t,

            output  wire                m_axi4s_rx_tfirst,
            output  wire                m_axi4s_rx_tlast,
            output  wire    [7:0]       m_axi4s_rx_tdata,
            output  wire                m_axi4s_rx_tvalid,

            input   wire                s_axi4s_tx_tlast,
            input   wire    [7:0]       s_axi4s_tx_tdata,
            input   wire                s_axi4s_tx_tvalid,
            output  wire                s_axi4s_tx_tready
        );

    (* IOB = "true" *)  logic           rx0_en;
    (* IOB = "true" *)  logic   [1:0]   rx0_data;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            rx0_en   <= 1'b0;
            rx0_data <= 'x;
        end
        else begin
            rx0_en   <= rmii_crs;
            rx0_data <= rmii_rx;
        end
    end


    logic           rx1_en;
    logic   [1:0]   rx1_data;
    logic           rx1_first;
    logic           rx1_last;
    always_comb rx1_last  = !rx0_en;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            rx1_en    <= 1'b0;
            rx1_data  <= 'x;
            rx1_first <= 'x;
        end
        else begin
            rx1_first <= 1'b0;
            if ( !rx0_en ) begin
                rx1_en <= 1'b0;
            end
            else if ( !rx1_en && rx0_en && rx0_data != 0 ) begin
                rx1_en    <= 1'b1;
                rx1_first <= 1'b1;
            end
            rx1_data <= rx0_data;
        end
    end

    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2),
                .S_NUM              (1),
                .M_NUM              (4),
                .HAS_FIRST          (1),  // first を備える
                .HAS_LAST           (1),  // last を備える
                .HAS_STRB           (0),  // strb を備える
                .HAS_KEEP           (0),  // keep を備える
                .AUTO_FIRST         (0),  // last の次を自動的に first とする
                .HAS_ALIGN_S        (0),  // slave 側のアライメントを指定する
                .HAS_ALIGN_M        (0),  // master 側のアライメントを指定する
                .FIRST_OVERWRITE    (1),  // first時前方に残変換があれば吐き出さずに上書き
                .FIRST_FORCE_LAST   (1),  // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
                .REDUCE_KEEP        (0),
                .USER_F_WIDTH       (0),
                .USER_L_WIDTH       (0),
                .S_REGS             (1),
                .M_REGS             (1)
            )
        i_stream_width_convert_rx
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),
                
                .endian             (1'b0),
                .padding            ('0),
                
                .s_align_s          ('0),
                .s_align_m          ('0),
                .s_first            (rx1_first),
                .s_last             (rx1_last),
                .s_data             (rx1_data),
                .s_strb             ('0),
                .s_keep             ('0),
                .s_user_f           ('0),
                .s_user_l           ('0),
                .s_valid            (rx1_en | rx1_first),
                .s_ready            (),
                
                .m_first            (m_axi4s_rx_tfirst),
                .m_last             (m_axi4s_rx_tlast),
                .m_data             (m_axi4s_rx_tdata),
                .m_strb             (),
                .m_keep             (),
                .m_user_f           (),
                .m_user_l           (),
                .m_valid            (m_axi4s_rx_tvalid),
                .m_ready            (1'b1)
            );
    

    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2),
                .S_NUM              (4),
                .M_NUM              (1),
                .HAS_FIRST          (0),  // first を備える
                .HAS_LAST           (1),  // last を備える
                .HAS_STRB           (0),  // strb を備える
                .HAS_KEEP           (0),  // keep を備える
                .AUTO_FIRST         (0),  // last の次を自動的に first とする
                .HAS_ALIGN_S        (0),  // slave 側のアライメントを指定する
                .HAS_ALIGN_M        (0),  // master 側のアライメントを指定する
                .FIRST_OVERWRITE    (1),  // first時前方に残変換があれば吐き出さずに上書き
                .FIRST_FORCE_LAST   (1),  // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
                .REDUCE_KEEP        (0),
                .USER_F_WIDTH       (0),
                .USER_L_WIDTH       (0),
                .S_REGS             (1),
                .M_REGS             (1)
            )
        i_stream_width_convert_tx
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),
                
                .endian             (1'b0),
                .padding            ('0),
                
                .s_align_s          ('0),
                .s_align_m          ('0),
                .s_first            ('0),
                .s_last             (s_axi4s_tx_tlast),
                .s_data             (s_axi4s_tx_tdata),
                .s_strb             ('0),
                .s_keep             ('0),
                .s_user_f           ('0),
                .s_user_l           ('0),
                .s_valid            (s_axi4s_tx_tvalid),
                .s_ready            (s_axi4s_tx_tready),
                
                .m_first            (),
                .m_last             (),
                .m_data             (rmii_tx),
                .m_strb             (),
                .m_keep             (),
                .m_user_f           (),
                .m_user_l           (),
                .m_valid            (rmii_txen),
                .m_ready            (1'b1)
            );
    
endmodule


`default_nettype wire

