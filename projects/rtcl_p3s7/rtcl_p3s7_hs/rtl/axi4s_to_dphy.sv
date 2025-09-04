

`timescale 1ns / 1ps
`default_nettype none

module axi4s_to_dphy
        #(
            parameter   int     CHANNELS       = 4                      ,
            parameter   int     RAW_BITS       = 10                     ,
            parameter   int     DPHY_LANES     = 2                      ,
            parameter           DEBUG          = "false"                
        )
        (
            jelly3_axi4s_if.s                           s_axi4s         ,

            input   var logic                           dphy_reset      ,
            input   var logic                           dphy_clk        ,
            output  var logic   [DPHY_LANES-1:0][7:0]   dphy_data       ,
            output  var logic                           dphy_request    ,
            input   var logic                           dphy_ready      
        );

    localparam  type    raw_t = logic [RAW_BITS-1:0];

    localparam  AXI4S_TDATA_BITS = CHANNELS * $bits(raw_t)  ;
    localparam  AXI4S_TUSER_BITS = s_axi4s.USER_BITS        ;

    // FIFO
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (AXI4S_TDATA_BITS   ),
                .USER_BITS      (AXI4S_TUSER_BITS   ),
                .DEBUG          (DEBUG              )
            )
        axi4s_fifo
            (
                .aresetn        (~dphy_reset        ),
                .aclk           (dphy_clk           ),
                .aclken         (1'b1               )
            );
    
    // Async FIFO
    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (axi4s_fifo         ),
                .s_free_size    (                   ),
                .m_data_size    (                   )
            );

    // パケットタイプ
    localparam  type    packet_type_t = logic [7:0];

    // packet_type[3:0]: 1011 (magic number)
    // packet_type[4]  : 0: 8bit,  1: 10bit
    // packet_type[5]  : 0 (reserve)
    // packet_type[6]  : 0 (reserve)
    // packet_type[7]  : 0 (reserve)
    packet_type_t   packet_type   ;
//  assign packet_type = {2'b00, axi4s_fifo.tuser[3], 1'b1, 4'b1011};
    assign packet_type = {3'b000, 1'b1, 4'b1011};


    raw_t   [CHANNELS-1:0]    conv_data   ;
    logic                     conv_first  ;
    logic                     conv_last   ;
    packet_type_t             conv_user   ;
    logic                     conv_valid  ;
    logic                     conv_ready  ;
    /*
    assign conv_data    = axi4s_fifo.tvalid ? axi4s_fifo.tdata   : '0;
    assign conv_first   = axi4s_fifo.tvalid ? axi4s_fifo.tuser[0]: '0;  // frame_start
    assign conv_last    = axi4s_fifo.tvalid ? axi4s_fifo.tuser[1]: '0;  // frame_end
    assign conv_user    = axi4s_fifo.tvalid ? packet_type        : '0;
    assign conv_valid   = 1'b1;  // always valid
    assign axi4s_fifo.tready = !conv_valid || conv_ready;
    */
    always_ff @(posedge dphy_clk) begin
        if ( dphy_reset ) begin
            conv_data  <= 'x;
            conv_first <= 'x;
            conv_last  <= 'x;
            conv_user  <= 'x;
            conv_valid <= 1'b0;
        end
        else begin
            if ( axi4s_fifo.tready ) begin
            conv_data  <= axi4s_fifo.tvalid ? axi4s_fifo.tdata   : '0;
            conv_first <= axi4s_fifo.tvalid ? axi4s_fifo.tuser[0]: '0;  // frame_start
            conv_last  <= axi4s_fifo.tvalid ? axi4s_fifo.tuser[1]: '0;  // frame_end
            conv_user  <= axi4s_fifo.tvalid ? packet_type        : '0;
            conv_valid <= 1'b1;  // always valid
            end
        end
    end
    assign axi4s_fifo.tready = !conv_valid || conv_ready;

    // debug
    raw_t   conv_data0   ;
    raw_t   conv_data1   ;
    raw_t   conv_data2   ;
    raw_t   conv_data3   ;
    assign conv_data0 = conv_data[0];
    assign conv_data1 = conv_data[1];
    assign conv_data2 = conv_data[2];
    assign conv_data3 = conv_data[3];

    jelly3_axi4s_if
            #(
                .USE_LAST           (1                      ),
                .USE_USER           (1                      ),
                .DATA_BITS          (DPHY_LANES*8           ),
                .USER_BITS          ($bits(packet_type) + 1 ),
                .DEBUG              (DEBUG                  )
            )
        axi4s_dphy
            (
                .aresetn            (~dphy_reset            ),
                .aclk               (dphy_clk               ),
                .aclken             (1'b1                   )
            );
    
    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2                      ),
                .S_NUM              (CHANNELS*5             ),
                .M_NUM              (DPHY_LANES*4           ),
                .HAS_FIRST          (1                      ),
                .HAS_LAST           (1                      ),
                .HAS_STRB           (0                      ),
                .HAS_KEEP           (0                      ),
                .AUTO_FIRST         (0                      ),
                .HAS_ALIGN_S        (0                      ),
                .HAS_ALIGN_M        (0                      ),
                .FIRST_OVERWRITE    (0                      ),
                .FIRST_FORCE_LAST   (0                      ),
                .REDUCE_KEEP        (0                      ),
                .USER_F_WIDTH       (8                      ),
                .USER_L_WIDTH       (0                      ),
                .S_REGS             (1                      ),
                .M_REGS             (1                      )
            )
        u_stream_width_convert
            (
                .reset              (dphy_reset             ),
                .clk                (dphy_clk               ),
                .cke                (1'b1                   ),

                .endian             (1'b0                   ),
                .padding            ('0                     ),
                
                .s_align_s          ('0                     ),
                .s_align_m          ('0                     ),
                .s_first            (conv_first             ),
                .s_last             (conv_last              ),
                .s_data             (conv_data              ),
                .s_strb             ('1                     ),
                .s_keep             ('1                     ),
                .s_user_f           (conv_user              ),
                .s_user_l           (                       ),
                .s_valid            (conv_valid             ),
                .s_ready            (conv_ready             ),

                .m_first            (axi4s_dphy.tuser[0]    ),
                .m_last             (axi4s_dphy.tlast       ),
                .m_data             (axi4s_dphy.tdata       ),
                .m_strb             (                       ),
                .m_keep             (                       ),
                .m_user_f           (axi4s_dphy.tuser[8:1]  ),
                .m_user_l           (                       ),
                .m_valid            (axi4s_dphy.tvalid      ),
                .m_ready            (axi4s_dphy.tready      )
            );

    // DPHY TX
    dphy_hs_tx
            #(
                .DATA_BITS          (DPHY_LANES * 8         )
            )
        u_dphy_hs_tx
            (
                .reset              (dphy_reset             ),
                .clk                (dphy_clk               ),

                .s_axi4s            (axi4s_dphy.s           ),

                .dphy_data          (dphy_data              ),
                .dphy_request       (dphy_request           ),
                .dphy_ready         (dphy_ready             )
            );

endmodule

`default_nettype wire

// end of file
