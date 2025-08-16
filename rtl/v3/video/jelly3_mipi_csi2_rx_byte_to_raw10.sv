
`timescale 1ns / 1ps
`default_nettype none


module jelly3_mipi_csi2_rx_byte_to_raw10
        #(
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            jelly3_axi4s_if.s   s_axi4s,
            jelly3_axi4s_if.m   m_axi4s
        );
    
    localparam  int     S_LANES = s_axi4s.DATA_BITS /  8;
    localparam  int     M_LANES = m_axi4s.DATA_BITS / 10;

    logic   [0:0]       conv_tuser;
    logic               conv_tlast;
    logic   [8*5-1:0]   conv_tdata8;
    logic   [10*4-1:0]  conv_tdata10;
    logic               conv_tvalid;
    logic               conv_tready;
    
    jelly3_stream_width_convert
            #(
                .UNIT_BITS          (8                  ),
                .S_NUM              (S_LANES            ),
                .M_NUM              (5                  ),
                .USE_FIRST          (1                  ),
                .USE_LAST           (1                  ),
                .USE_ALIGN_S        (0                  ),
                .USE_ALIGN_M        (0                  ),
                .AUTO_FIRST         (0                  ),
                .FIRST_OVERWRITE    (1                  ),
                .FIRST_FORCE_LAST   (0                  ),
                .ALIGN_S_BITS       (1                  ),
                .ALIGN_M_BITS       (1                  ),
                .S_REG              (1                  ),
                .M_REG              (1                  )
            )
        u_data_stream_convert_s
            (
                .reset              (~s_axi4s.aresetn   ),
                .clk                (s_axi4s.aclk       ),
                .cke                (s_axi4s.aclken     ),
                
                .endian             (1'b0               ),
                .padding            ('x                 ),
                
                .s_user_l           ('0                 ),
                .s_user_f           ('0                 ),
                .s_keep             ('0                 ),
                .s_strb             ('0                 ),
                .s_align_s          (1'b0               ),
                .s_align_m          (1'b0               ),
                .s_first            (s_axi4s.tuser      ),
                .s_last             (s_axi4s.tlast      ),
                .s_data             (s_axi4s.tdata      ),
                .s_valid            (s_axi4s.tvalid     ),
                .s_ready            (s_axi4s.tready     ),
                
                .m_user_l           (                   ),
                .m_user_f           (                   ),
                .m_keep             (                   ),
                .m_strb             (                   ),
                .m_first            (conv_tuser         ),
                .m_last             (conv_tlast         ),
                .m_data             (conv_tdata8        ),
                .m_valid            (conv_tvalid        ),
                .m_ready            (conv_tready        )
            );
    
    wire    [7:0]   lsb_data = conv_tdata8[4*8 +: 8];
    
    assign conv_tdata10[0*10 +: 10] = {conv_tdata8[0*8 +: 8], lsb_data[0*2 +: 2]};
    assign conv_tdata10[1*10 +: 10] = {conv_tdata8[1*8 +: 8], lsb_data[1*2 +: 2]};
    assign conv_tdata10[2*10 +: 10] = {conv_tdata8[2*8 +: 8], lsb_data[2*2 +: 2]};
    assign conv_tdata10[3*10 +: 10] = {conv_tdata8[3*8 +: 8], lsb_data[3*2 +: 2]};
    
    jelly3_stream_width_convert
            #(
                .UNIT_BITS          (10                 ),
                .S_NUM              (4                  ),
                .M_NUM              (M_LANES            ),
                .USE_FIRST          (1                  ),
                .USE_LAST           (1                  ),
                .USE_ALIGN_S        (0                  ),
                .USE_ALIGN_M        (0                  ),
                .AUTO_FIRST         (0                  ),
                .FIRST_OVERWRITE    (1                  ),
                .FIRST_FORCE_LAST   (0                  ),
                .ALIGN_S_BITS       (1                  ),
                .ALIGN_M_BITS       (1                  ),
                .S_REG              (1                  ),
                .M_REG              (1                  )
            )
        u_stream_width_convert_m
            (
                .reset              (~s_axi4s.aresetn   ),
                .clk                (s_axi4s.aclk       ),
                .cke                (s_axi4s.aclken     ),
                
                .endian             (1'b0               ),
                .padding            ('x                 ),
                
                .s_user_l           ('0                 ),
                .s_user_f           ('0                 ),
                .s_keep             ('0                 ),
                .s_strb             ('0                 ),
                .s_align_s          (1'b0               ),
                .s_align_m          (1'b0               ),
                .s_first            (conv_tuser         ),
                .s_last             (conv_tlast         ),
                .s_data             (conv_tdata10       ),
                .s_valid            (conv_tvalid        ),
                .s_ready            (conv_tready        ),
                
                .m_user_f           (                   ),
                .m_user_l           (                   ),
                .m_keep             (                   ),
                .m_strb             (                   ),
                .m_first            (m_axi4s.tuser      ),
                .m_last             (m_axi4s.tlast      ),
                .m_data             (m_axi4s.tdata      ),
                .m_valid            (m_axi4s.tvalid     ),
                .m_ready            (m_axi4s.tready     )
            );
    
endmodule


`default_nettype wire


// end of file
