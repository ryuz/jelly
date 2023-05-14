

`timescale 1ns / 1ps
`default_nettype none

module rmii_phy
        #(
            parameter   bit     ASYNC             = 1,
            parameter   int     RX_FIFO_PTR_WIDTH = 3,
            parameter   int     TX_FIFO_PTR_WIDTH = 3,
            parameter           DEBUG             = "false"
        )
        (
            input   wire                aresetn,
            input   wire                aclk,
            
            output  wire                m_axi4s_rx_tfirst,
            output  wire                m_axi4s_rx_tlast,
            output  wire    [7:0]       m_axi4s_rx_tdata,
            output  wire                m_axi4s_rx_tvalid,

            input   wire                s_axi4s_tx_tlast,
            input   wire    [7:0]       s_axi4s_tx_tdata,
            input   wire                s_axi4s_tx_tvalid,
            output  wire                s_axi4s_tx_tready,

            input   wire                rmii_refclk,
            output  wire                rmii_txen,
            output  wire    [1:0]       rmii_tx,
            input   wire    [1:0]       rmii_rx,
            input   wire                rmii_crs,
            input   wire                rmii_mdc,
            output  wire                rmii_mdio_t,
            output  wire                rmii_mdio_o,
            input   wire                rmii_mdio_i
        );


    // clock & reset
    logic           rmii_reset;
    logic           rmii_clk;

//    assign rmii_clk = rmii_refclk;
    BUFG    i_bufg  (.I(rmii_refclk), .O(rmii_clk));
    
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1),
                .OUT_LOW_ACTIVE     (0),
                .INPUT_REGS         (2)
            )
        i_reset
            (
                .clk                (rmii_clk),
                .in_reset           (aresetn),
                .out_reset          (rmii_reset)
            );


    // -------------------------
    //  RX
    // -------------------------

    // stage 0
    (* IOB = "true" *)  logic           rx0_en;
    (* IOB = "true" *)  logic   [1:0]   rx0_data;
    always_ff @(posedge rmii_clk) begin
        if ( rmii_reset ) begin
            rx0_en   <= 1'b0;
            rx0_data <= 'x;
        end
        else begin
            rx0_en   <= rmii_crs;
            rx0_data <= rmii_rx;
        end
    end


    // stage 1
    logic           rx1_en;
    logic   [1:0]   rx1_data;
    logic           rx1_first;
    logic           rx1_last;
    always_comb rx1_last  = !rx0_en;

    always_ff @(posedge rmii_clk) begin
        if ( rmii_reset ) begin
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

    // stage 2
    logic           rx2_first;
    logic           rx2_last;
    logic   [1:0]   rx2_data;
    logic           rx2_valid;

    jelly2_fifo_generic_fwtf
            #(
                .ASYNC              (ASYNC),
                .DATA_WIDTH         (2+2),
                .PTR_WIDTH          (RX_FIFO_PTR_WIDTH),
                .DOUT_REGS          (0),
                .RAM_TYPE           ("distributed"),
                .LOW_DEALY          (1),
                .S_REGS             (0),
                .M_REGS             (0)
            )   
        u_fifo_generic_fwtf_rx
            (   
                .s_reset            (rmii_reset),
                .s_clk              (rmii_clk),
                .s_cke              (1'b1),
                .s_data             ({rx1_first, rx1_last, rx1_data}),
                .s_valid            (rx1_en | rx1_first),
                .s_ready            (),
                .s_free_count       (),

                .m_reset            (~aresetn),
                .m_clk              (aclk),
                .m_cke              (1'b1),
                .m_data             ({rx2_first, rx2_last, rx2_data}),
                .m_valid            (rx2_valid),
                .m_ready            (1'b1),
                .m_data_count       ()
            );

    // stage 3
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
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (1'b1),
                
                .endian             (1'b0),
                .padding            ('0),
                
                .s_align_s          ('0),
                .s_align_m          ('0),
                .s_first            (rx2_first),
                .s_last             (rx2_last),
                .s_data             (rx2_data),
                .s_strb             ('0),
                .s_keep             ('0),
                .s_user_f           ('0),
                .s_user_l           ('0),
                .s_valid            (rx2_valid),
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
    


    // -------------------------
    //  TX
    // -------------------------

    logic           tx_last;
    logic   [1:0]   tx_data;
    logic           tx_valid;
    logic           tx_ready;

    logic           tx_enable;

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
                .reset              (~aresetn),
                .clk                (aclk),
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
                .m_last             (tx_last),
                .m_data             (tx_data),
                .m_strb             (),
                .m_keep             (),
                .m_user_f           (),
                .m_user_l           (),
                .m_valid            (tx_valid),
                .m_ready            (tx_ready & tx_enable)
            );
    
    // 1サイクル溜める
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            tx_enable <= 1'b0;
        end
        else begin
            if ( tx_valid ) begin
                tx_enable <= 1'b1;
            end
            if ( tx_valid && tx_ready && tx_last ) begin
                tx_enable <= 1'b0;
            end
        end
    end
    
//  assign tx_enable = 1'b1;    // 溜めない

    jelly2_fifo_generic_fwtf
            #(
                .ASYNC              (ASYNC),
                .DATA_WIDTH         (2),
                .PTR_WIDTH          (TX_FIFO_PTR_WIDTH),
                .DOUT_REGS          (0),
                .RAM_TYPE           ("distributed"),
                .LOW_DEALY          (1),
                .S_REGS             (0),
                .M_REGS             (0)
            )   
        u_fifo_generic_fwtf_tx
            (   
                .s_reset            (~aresetn),
                .s_clk              (aclk),
                .s_cke              (1'b1),
                .s_data             (tx_data),
                .s_valid            (tx_valid & tx_enable),
                .s_ready            (tx_ready),
                .s_free_count       (),

                .m_reset            (rmii_reset),
                .m_clk              (rmii_clk),
                .m_cke              (1'b1),
                .m_data             (rmii_tx),
                .m_valid            (rmii_txen),
                .m_ready            (1'b1),
                .m_data_count       ()
            );

    generate
    if ( 256'(DEBUG) == 256'("true") || 256'(DEBUG) == 256'("TRUE") ) begin : blk_debug
        (* mark_debug = "true" *)   logic           dbg_rx_en;
        (* mark_debug = "true" *)   logic   [1:0]   dbg_rx_data;
        (* mark_debug = "true" *)   logic           dbg_tx_en;
        (* mark_debug = "true" *)   logic   [1:0]   dbg_tx_data;
        always_ff @(posedge rmii_clk) begin
            dbg_rx_en   <= rx0_en   ;
            dbg_rx_data <= rx0_data ;
            dbg_tx_en   <= rmii_txen;
            dbg_tx_data <= rmii_tx  ;
        end
    end
    endgenerate

endmodule


`default_nettype wire

