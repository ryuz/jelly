
`timescale 1ns / 1ps
`default_nettype none


module tb_mipi_csi2_raw10();
    
    initial begin
        $dumpfile("tb_mipi_csi2_raw10.vcd");
        $dumpvars(0, tb_mipi_csi2_raw10);
    
    #500000
        $finish;
    end
    

    // -----------------------------
    //  reset & clock
    // -----------------------------

    localparam RATE_200  = 1000.0/200.0;
    localparam RATE_250  = 1000.0/250.0;
    localparam RATE_DPHY = 1000.0/114.0;

    logic   reset = 1'b1;
    initial #(RATE_200*100)  reset = 1'b0;

    logic   clk200 = 1'b1;
    initial forever #(RATE_200/2.0)     clk200 = ~clk200;
    
    logic   clk250 = 1'b1;
    initial forever #(RATE_250/2.0)     clk250 = ~clk250;

    logic   dphy_clk = 1'b1;
    initial forever #(RATE_DPHY/2.0)    dphy_clk = ~dphy_clk;


    // -----------------------------
    //  master RAW10
    // -----------------------------

    localparam          DEVICE         = "RTL"      ;
    localparam          SIMULATION     = "true"     ;
    localparam          DEBUG          = "false"    ;

    localparam  int     IMG_WIDTH   = 64 ;
    localparam  int     IMG_HEIGHT  = 16 ;
    localparam  int     H_BLANK     = 64 ;
    localparam  int     V_BLANK     = 8  ;

    wire    logic   tx_cam_reset = reset    ;
    wire    logic   tx_cam_clk   = clk250   ;

    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (10                 )
            )
        axi4s_tx_raw10
            (
                .aresetn        (~tx_cam_reset      ),
                .aclk           (tx_cam_clk         ),
                .aclken         (1'b1               )
            );

    jelly3_model_axi4s_m
            #(
                .COMPONENTS     (1                  ),
                .DATA_BITS      (10                 ),
                .IMG_WIDTH      (IMG_WIDTH          ),
                .IMG_HEIGHT     (IMG_HEIGHT         ),
                .H_BLANK        (H_BLANK            ),
                .V_BLANK        (V_BLANK            )
            )
        u_model_axi4s_m
            (
                .enable         (1'b1               ),
                .busy           (                   ),

                .m_axi4s        (axi4s_tx_raw10.m   ),
                .out_x          (                   ),
                .out_y          (                   ),
                .out_f          (                   )
            );


    // RAW10 to 2byte
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_tx_2byte
            (
                .aresetn        (~tx_cam_reset      ),
                .aclk           (tx_cam_clk         ),
                .aclken         (1'b1               )
            );

    jelly3_mipi_csi2_tx_raw10_to_2byte
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi2_tx_raw10_to_2byte
            (
                .s_axi4s        (axi4s_tx_raw10.s   ),
                .m_axi4s        (axi4s_tx_2byte.m   )
            );

    // FIFO
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_tx_fifo
            (
                .aresetn        (~reset             ),
                .aclk           (dphy_clk           ),
                .aclken         (1'b1               )
            );

    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo_tx
            (
                .s_axi4s        (axi4s_tx_2byte.s   ),
                .m_axi4s        (axi4s_tx_fifo.m    ),

                .s_free_size    (                   ),
                .m_data_size    (                   )
            );


    // mipi_csi_tx_gen_2lane
    logic       tx_frame_start;
    jelly3_pulse_async
            #(
                .ASYNC          (1                  ),
                .SYNC_FF        (2                  ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_pulse_async
            (
                .s_reset        (~axi4s_tx_raw10.aresetn),
                .s_clk          (axi4s_tx_raw10.aclk    ),
                .s_cke          (axi4s_tx_raw10.aclken  ),
                .s_pulse        (axi4s_tx_raw10.tvalid && axi4s_tx_raw10.tready && axi4s_tx_raw10.tuser[0]),
                
                .m_reset        (reset                  ),
                .m_clk          (dphy_clk               ),
                .m_cke          (1'b1                   ),
                .m_pulse        (tx_frame_start         )
            );
    
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_tx_dphy
            (
                .aresetn        (~reset             ),
                .aclk           (dphy_clk           ),
                .aclken         (1'b1               )
            );

    logic   [7:0]   param_type  ;
    logic   [15:0]  param_wc    ;
    assign param_type = 8'h2b;  // RAW10
    assign param_wc   = 16'(IMG_WIDTH * 10 / 8);
    jelly3_mipi_csi2_tx_packet_2lane
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi2_tx_packet_2lane
            (
                .param_type      ,
                .param_wc        ,

                .frame_start     (tx_frame_start    ),
                .frame_end       (1'b0              ),

                .s_axi4s         (axi4s_tx_fifo.s   ),
                .m_axi4s         (axi4s_tx_dphy.m   )
            );

    int axi4s_tx_dphy_count = 0;
    always_ff @(posedge dphy_clk) begin
        if ( axi4s_tx_dphy.tvalid && axi4s_tx_dphy.tready ) begin
            axi4s_tx_dphy_count <= axi4s_tx_dphy_count + 1;
        end
        else begin
            axi4s_tx_dphy_count <= 0;
        end
    end


    // DPYH-TX
    logic   [1:0][7:0]  dphy_tx_datahs  ;
    logic               dphy_tx_validhs ;
    logic               dphy_tx_readyhs ;
    int                 dphy_tx_count   ;
    always_ff @(posedge dphy_clk) begin
        if ( reset || !dphy_tx_validhs ) begin
            dphy_tx_readyhs <= 1'b0 ;
            dphy_tx_count   <= 11   ;
        end
        else begin
            if ( dphy_tx_count > 0 ) begin
                dphy_tx_count   <= dphy_tx_count - 1;
                dphy_tx_readyhs <= 1'b0 ;
            end
            else begin
                dphy_tx_readyhs <= 1'b1 ;
            end
        end
    end

    assign dphy_tx_datahs  = axi4s_tx_dphy.tdata    ;
    assign dphy_tx_validhs = axi4s_tx_dphy.tvalid   ;
    assign axi4s_tx_dphy.tready = dphy_tx_readyhs   ;


    // -------------------------------------
    //  MIPI CSI-2 RX
    // -------------------------------------

    // dphy_rx
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_rx_dphy
            (
                .aresetn        (~reset             ),
                .aclk           (dphy_clk           ),
                .aclken         (1'b1               )
            );

    always_ff @(posedge dphy_clk) begin
        if ( reset ) begin
            axi4s_rx_dphy.tuser   <= 1'b1   ;
            axi4s_rx_dphy.tdata   <= '0     ;
            axi4s_rx_dphy.tvalid  <= 1'b0   ;
        end
        else begin
            axi4s_rx_dphy.tuser   <= ~axi4s_rx_dphy.tvalid  ;
            axi4s_rx_dphy.tdata   <= dphy_tx_datahs         ;
            axi4s_rx_dphy.tvalid  <= dphy_tx_readyhs        ;
        end
    end
    assign axi4s_rx_dphy.tlast = (axi4s_rx_dphy.tvalid && ~dphy_tx_readyhs);

    // rx_fifo
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_rx_fifo
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );

    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo_rx
            (
                .s_axi4s        (axi4s_rx_dphy.s    ),
                .m_axi4s        (axi4s_rx_fifo.m    ),

                .s_free_size    (                   ),
                .m_data_size    (                   )
            );


    // rx
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (16                 )
            )
        axi4s_rx_packet
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );
    
    logic           rx_frame_start      ;
    logic           rx_frame_end        ;
    logic           rx_ecc_corrected    ;
    logic           rx_ecc_error        ;
    logic           rx_ecc_valid        ;
    logic           rx_crc_error        ;
    logic           rx_crc_valid        ;
    logic           rx_packet_lost      ;
    jelly3_mipi_csi2_rx_packet_2lane
        u_mipi_csi2_rx_packet_2lane
            (
                .param_data_type    (8'h2b              ),
                
                .out_frame_start    (rx_frame_start     ),
                .out_frame_end      (rx_frame_end       ),
                .out_ecc_corrected  (rx_ecc_corrected   ),
                .out_ecc_error      (rx_ecc_error       ),
                .out_ecc_valid      (rx_ecc_valid       ),
                .out_crc_error      (rx_crc_error       ),
                .out_crc_valid      (rx_crc_valid       ),
                .out_packet_lost    (rx_packet_lost     ),

                .s_axi4s            (axi4s_rx_fifo.s    ),
                .m_axi4s            (axi4s_rx_packet.m  )
            );

//    assign axi4s_rx_packet.tready = 1'b1;

    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (10                 )
            )
        axi4s_rx_raw10
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );

    jelly3_mipi_csi2_rx_2byte_to_raw10
        u_mipi_csi2_rx_2byte_to_raw10
            (
                .s_axi4s        (axi4s_rx_packet.s  ),
                .m_axi4s        (axi4s_rx_raw10.m   )
            );
    
    assign axi4s_rx_raw10.tready = 1'b1;



    /*
    // width convert
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (8                  )
            )
        axi4s_rx_byte
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );

    jelly_data_width_converter
            #(
                .UNIT_WIDTH     (8                      ),
                .S_DATA_SIZE    (1                      ),
                .M_DATA_SIZE    (0                      )
            )
        u_data_width_converter
            (
                .reset          (~axi4s_rx_fifo.aresetn ),
                .clk            (axi4s_rx_fifo.aclk     ),
                .cke            (1'b1),
                
                .endian         (1'b0),
                
                .s_data         (axi4s_rx_fifo.tdata    ),
                .s_first        (axi4s_rx_fifo.tuser[0] ),
                .s_last         (axi4s_rx_fifo.tlast    ),
                .s_valid        (axi4s_rx_fifo.tvalid   ),
                .s_ready        (axi4s_rx_fifo.tready   ),
                
                .m_data         (axi4s_rx_byte.tdata    ),
                .m_first        (axi4s_rx_byte.tuser    ),
                .m_last         (axi4s_rx_byte.tlast    ),
                .m_valid        (axi4s_rx_byte.tvalid   ),
                .m_ready        (axi4s_rx_byte.tready   )
            );


    // rx
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (8                  )
            )
        axi4s_rx_packet
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );
    
    logic           rx_frame_start      ;
    logic           rx_frame_end        ;
    logic           rx_ecc_corrected    ;
    logic           rx_ecc_error        ;
    logic           rx_ecc_valid        ;
    logic           rx_crc_error        ;
    logic           rx_crc_valid        ;
    logic           rx_packet_lost      ;
    jelly3_mipi_csi2_rx_packet
        u_mipi_csi2_rx_packet
            (
                .param_data_type    (8'h2b              ),
                
                .out_frame_start    (rx_frame_start     ),
                .out_frame_end      (rx_frame_end       ),
                .out_ecc_corrected  (rx_ecc_corrected   ),
                .out_ecc_error      (rx_ecc_error       ),
                .out_ecc_valid      (rx_ecc_valid       ),
                .out_crc_error      (rx_crc_error       ),
                .out_crc_valid      (rx_crc_valid       ),
                .out_packet_lost    (rx_packet_lost     ),

                .s_axi4s            (axi4s_rx_byte.s    ),
                .m_axi4s            (axi4s_rx_packet.m  )
            );

    // rx raw10
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (10                 )
            )
        axi4s_rx_raw10
            (
                .aresetn        (~reset             ),
                .aclk           (clk250             ),
                .aclken         (1'b1               )
            );
    
    jelly2_mipi_csi2_rx_raw10
        u_mipi_csi2_rx_raw10
            (
                .aresetn        (axi4s_rx_packet.aresetn    ),
                .aclk           (axi4s_rx_packet.aclk       ),

                .s_axi4s_tuser  (axi4s_rx_packet.tuser      ),
                .s_axi4s_tlast  (axi4s_rx_packet.tlast      ),
                .s_axi4s_tdata  (axi4s_rx_packet.tdata      ),
                .s_axi4s_tvalid (axi4s_rx_packet.tvalid     ),
                .s_axi4s_tready (axi4s_rx_packet.tready     ),

                .m_axi4s_tuser  (axi4s_rx_raw10.tuser       ),
                .m_axi4s_tlast  (axi4s_rx_raw10.tlast       ),
                .m_axi4s_tdata  (axi4s_rx_raw10.tdata       ),
                .m_axi4s_tvalid (axi4s_rx_raw10.tvalid      ),
                .m_axi4s_tready (axi4s_rx_raw10.tready      )
            );
   

   assign axi4s_rx_raw10.tready = 1'b1;

    int axi4s_rx_raw10_count = 0;
    always_ff @(posedge axi4s_rx_raw10.aclk) begin
        if ( axi4s_rx_raw10.tvalid && axi4s_rx_raw10.tready ) begin
            if ( axi4s_rx_raw10.tlast ) begin
                axi4s_rx_raw10_count <= 0;
            end
            else begin
                axi4s_rx_raw10_count <= axi4s_rx_raw10_count + 1;
            end
        end
    end
    */

endmodule


`default_nettype wire


// end of file
