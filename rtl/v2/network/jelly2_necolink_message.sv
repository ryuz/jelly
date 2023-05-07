// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_message
        #(
            parameter   bit             ENABLE_BYPASS  = 1          ,
            parameter   int unsigned    MESSAGE_BYTES  = 4          ,
            parameter                   BUF_RAM_TYPE   = "block"    ,

            parameter   bit             DEBUG          = 1'b0       ,
            parameter   bit             SIMULATION     = 1'b0        
        )   
        (   
            input   var logic           reset                       ,
            input   var logic           clk                         ,
            input   var logic           cke                         ,

            input   var logic   [7:0]   node_self                   ,

            output  var logic           m_rx_first                  ,
            output  var logic           m_rx_last                   ,
            output  var logic   [7:0]   m_rx_src_node               ,
            output  var logic   [7:0]   m_rx_data                   ,
            output  var logic           m_rx_valid                  ,

            input   var logic   [7:0]   s_tx_dst_node               ,
            input   var logic   [7:0]   s_tx_data                   ,
            input   var logic           s_tx_valid                  ,
            output  var logic           s_tx_ready                  ,

            input   var logic           recv_enable                 ,
            input   var logic           recv_start                  ,
            input   var logic           recv_finish                 ,
            input   var logic           recv_fail                   ,
            input   var logic           recv_payload_setup          ,
            input   var logic   [15:0]  s_recv_payload_rx_index     ,
            input   var logic           s_recv_payload_rx_first     ,
            input   var logic           s_recv_payload_rx_last      ,
            input   var logic   [7:0]   s_recv_payload_rx_data      ,
            input   var logic           s_recv_payload_rx_valid     ,

            input   var logic           send_enable                 ,
            input   var logic           send_start                  ,
            input   var logic           send_finish                 ,
            input   var logic           send_fail                   ,
            input   var logic           send_payload_setup          ,
            input   var logic   [15:0]  s_send_payload_rx_index     ,
            input   var logic           s_send_payload_rx_first     ,
            input   var logic           s_send_payload_rx_last      ,
            input   var logic           s_send_payload_rx_valid     ,
            output  var logic   [7:0]   m_send_payload_tx_data      ,
            output  var logic           m_send_payload_tx_valid     ,
            input   var logic           m_send_payload_tx_ready     
        );


    // ---------------------------------
    //  buffer
    // ---------------------------------

    localparam  int unsigned    BUF_ADDR_WIDTH = $clog2(MESSAGE_BYTES);

    logic                           buf_enable      ;
    logic   [7:0]                   buf_dst_node    ;
    logic   [7:0]                   buf_src_node    ;

    logic                           buf_wr_en       ;
    logic   [BUF_ADDR_WIDTH-1:0]    buf_wr_addr     ;
    logic   [7:0]                   buf_wr_din      ;
            
    logic                           buf_rd_clk      ;
    logic                           buf_rd_en       ;
    logic   [BUF_ADDR_WIDTH-1:0]    buf_rd_addr     ;
    logic   [7:0]                   buf_rd_dout     ;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH         (BUF_ADDR_WIDTH     ),
                .DATA_WIDTH         (8                  ),
                .MEM_SIZE           (MESSAGE_BYTES      ),
                .RAM_TYPE           (BUF_RAM_TYPE       ),
                .DOUT_REGS          (1                  )
            )
        u_ram_simple_dualport
            (
                .wr_clk             (clk                ),
                .wr_en              (buf_wr_en & cke    ),
                .wr_addr            (buf_wr_addr        ),
                .wr_din             (buf_wr_din         ),

                .rd_clk             (clk                ),
                .rd_en              (buf_rd_en & cke    ),
                .rd_regcke          (buf_rd_en & cke    ),
                .rd_addr            (buf_rd_addr        ),
                .rd_dout            (buf_rd_dout        )
            );



    // ---------------------------------
    //  typedef
    // ---------------------------------

    typedef enum logic [2:0] {
        POS_IDLE     = 3'b000,
        POS_DST_NODE = 3'b001,
        POS_SRC_NODE = 3'b010,
        POS_MESSAGE  = 3'b100
    } t_packet_position;

    // state
    typedef enum logic [1:0] {
        ST_IDLE    = 2'b00,
        ST_MESSAGE = 2'b01,
        ST_BUFFER  = 2'b10
    } t_state;


    // ---------------------------------
    //  Receive Message
    // ---------------------------------
    
    t_packet_position   recv_pos;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( recv_payload_setup ) begin
                if ( recv_enable ) begin
                    recv_pos <= POS_DST_NODE;
                end
                else begin
                    recv_pos <= POS_IDLE;
                end
            end
            else begin
                if ( s_recv_payload_rx_valid ) begin
                    case ( recv_pos )
                    POS_DST_NODE: recv_pos <= POS_SRC_NODE;
                    POS_SRC_NODE: recv_pos <= POS_MESSAGE;
                    default: ;
                    endcase
                end
            end
        end
    end

    // パケット受信の状態判定
    t_state     sig_recv_state;
    always_comb begin
        sig_recv_state = ST_IDLE;
        if ( s_recv_payload_rx_data == node_self || s_recv_payload_rx_data == 8'hff ) begin
            sig_recv_state = ST_MESSAGE;  // 自分宛かブロードキャストなら受信
        end
        else begin
            if ( s_recv_payload_rx_data != 8'h00 ) begin
                if ( ENABLE_BYPASS ) begin
                    if ( buf_enable || s_tx_valid ) begin
                        sig_recv_state = ST_BUFFER;
                    end
                end
                else begin
                    sig_recv_state = ST_BUFFER;
                end
            end
        end
    end

    t_state     reg_recv_state;

//    t_state     recv_state;
//    assign recv_state = (recv_pos == POS_DST_NODE) ? sig_recv_state : reg_recv_state;

    // 受信状態管理
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            if ( s_recv_payload_rx_valid ) begin
                case ( recv_pos )
                POS_DST_NODE:
                    begin
                        reg_recv_state <= sig_recv_state;
                        case ( sig_recv_state )
//                      ST_MESSAGE: m_rx_dst_node <= s_recv_payload_rx_data;
                        ST_BUFFER:  buf_dst_node  <= s_recv_payload_rx_data;
                        default: ;
                        endcase
                    end

                POS_SRC_NODE:
                    begin
                        case ( reg_recv_state )
                        ST_MESSAGE: m_rx_src_node <= s_recv_payload_rx_data;
                        ST_BUFFER:  buf_src_node  <= s_recv_payload_rx_data;
                        default: ;
                        endcase
                    end
                default: ;
                endcase
            end
        end
    end

    // buffer write
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( recv_payload_setup ) begin
                buf_wr_addr <= '0;
            end
            else if ( buf_wr_en ) begin
                buf_wr_addr <= buf_wr_addr + 1'b1;
            end

            buf_wr_en  <= s_recv_payload_rx_valid && (reg_recv_state == ST_BUFFER) && (recv_pos == POS_MESSAGE);
            buf_wr_din <= s_recv_payload_rx_data;
        end
    end

    // recv message 
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_rx_first   <= 'x;
            m_rx_last    <= 'x;
            m_rx_data    <= 'x;
            m_rx_valid   <= 1'b0;
        end
        else if ( cke ) begin
            if ( recv_payload_setup ) begin
                m_rx_first <= 1'b1;
            end else if ( m_rx_valid ) begin
                m_rx_first <= 1'b0;
            end

            m_rx_last  <= s_recv_payload_rx_last;
            m_rx_data  <= s_recv_payload_rx_data;
            m_rx_valid <= s_recv_payload_rx_valid && (reg_recv_state == ST_MESSAGE) && (recv_pos == POS_MESSAGE);
        end
    end


    // ---------------------------------
    //  Send Message
    // ---------------------------------

    t_packet_position   send_pos;
    if ( ENABLE_BYPASS ) begin : tx_pos_bypass
        assign send_pos = recv_pos;
    end
    else begin : tx_pos
        always_ff @(posedge clk) begin
            if ( cke ) begin
                if ( send_payload_setup ) begin
                    if ( send_enable ) begin
                        send_pos <= POS_DST_NODE;
                    end
                    else begin
                        send_pos <= POS_IDLE;
                    end
                end
                else begin
                    if ( s_send_payload_rx_valid ) begin
                        case ( send_pos )
                        POS_DST_NODE: send_pos <= POS_SRC_NODE;
                        POS_SRC_NODE: send_pos <= POS_MESSAGE;
                        default: ;
                        endcase
                    end
                end
            end
        end
    end

    t_state     sig_send_state;
    always_comb begin
        sig_send_state = ST_IDLE;
        if ( ENABLE_BYPASS ) begin
            if ( s_recv_payload_rx_data != 8'hff ) begin
                if ( buf_enable ) begin
                    sig_send_state = ST_BUFFER;
                end
                else if ( s_tx_valid ) begin
                    sig_send_state = ST_MESSAGE;
                end
            end
        end
        else begin
            if ( buf_enable ) begin
                sig_send_state = ST_BUFFER;
            end
            else if ( s_tx_valid ) begin
                sig_send_state = ST_MESSAGE;
            end
        end
    end

    t_state     reg_send_state;
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            if ( m_send_payload_tx_ready ) begin
                m_send_payload_tx_valid <= 1'b0;
            end
            
            if ( s_send_payload_rx_valid ) begin
                m_send_payload_tx_data  <= ENABLE_BYPASS ? s_recv_payload_rx_data : 8'h00;
                m_send_payload_tx_valid <= 1'b1;
    
                case ( send_pos )
                POS_DST_NODE:
                    begin
                        reg_send_state <= sig_send_state;
                        if ( ENABLE_BYPASS && s_recv_payload_rx_data == node_self ) begin
                            m_send_payload_tx_data <= 8'h00;
                        end
                        
                        case ( sig_send_state )
                        ST_MESSAGE: m_send_payload_tx_data <= s_tx_dst_node;
                        ST_BUFFER:  m_send_payload_tx_data <= buf_dst_node;
                        default: ;
                        endcase
                    end

                POS_SRC_NODE:
                    begin
                        case ( reg_send_state )
                        ST_MESSAGE: m_send_payload_tx_data <= node_self;
                        ST_BUFFER:  m_send_payload_tx_data <= buf_src_node;
                        default: ;
                        endcase
                    end

                POS_MESSAGE:
                    begin
                        case ( reg_send_state )
                        ST_MESSAGE: m_send_payload_tx_data <= s_tx_data;
                        ST_BUFFER:  m_send_payload_tx_data <= buf_rd_dout;
                        default: ;
                        endcase
                    end

                default: ;
                endcase
            end
        end
    end


    // buffer read
    assign buf_rd_en   = send_enable && s_send_payload_rx_valid && (reg_send_state == ST_BUFFER);
    always_ff @(posedge clk) begin
        if ( send_payload_setup ) begin
            buf_rd_addr <= '0;
        end
        else if ( cke ) begin
            if ( buf_rd_en ) begin
                buf_rd_addr <= buf_rd_addr + 1'b1;
            end
        end
    end

    // send
    logic   reg_tx_ready;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_tx_ready <= 1'b0;
        end
        else if ( cke ) begin
            if ( s_send_payload_rx_valid ) begin
                if ( send_pos == POS_SRC_NODE && reg_send_state == ST_MESSAGE ) begin
                    reg_tx_ready <= 1'b1;
                end
                if ( s_send_payload_rx_last ) begin
                    reg_tx_ready <= 1'b0;
                end
            end
        end
    end
    assign s_tx_ready = s_send_payload_rx_valid && reg_tx_ready;


    // ---------------------------------
    //  Buffer enable
    // ---------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            buf_enable <= 1'b0;
        end
        else if ( cke ) begin
            if ( send_enable && send_finish && reg_send_state == ST_BUFFER ) begin
                buf_enable <= 1'b0;
            end
            if ( recv_enable && recv_finish && reg_recv_state == ST_BUFFER ) begin
                buf_enable <= 1'b0;
            end
        end
    end


endmodule


`default_nettype wire

// end of file
