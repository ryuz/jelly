

`timescale 1ns / 1ps
`default_nettype none

module rtcl_p37s_hs_dphy_recv
        #(
            parameter   int     CHANNELS       = 1                          ,
            parameter   int     RAW_BITS       = 10                         ,
            parameter   int     DPHY_LANES     = 2                          ,
            parameter           DEBUG          = "false"                    
        )
        (
            input   var logic                           dphy_reset      ,
            input   var logic                           dphy_clk        ,
            input   var logic   [DPHY_LANES-1:0][7:0]   dphy_data       ,
            input   var logic                           dphy_valid      ,

            jelly3_axi4s_if.m                           m_axi4s         
        );

    // DPHY Receive
    logic                           rx_first    ;
    logic   [7:0]                   rx_type     ;
    logic   [DPHY_LANES-1:0][7:0]   rx_data     ;
    logic                           rx_valid    ;
    always_ff @(posedge dphy_clk) begin
        if ( dphy_reset ) begin
            rx_first <= 1'b0    ;
            rx_type  <= 8'hxx   ;
            rx_data  <= 'x      ;
            rx_valid <= 1'b0    ;
        end
        else begin
            if ( dphy_valid ) begin
                if ( !rx_valid ) begin
                    if ( !rx_first ) begin
                        rx_type  <= dphy_data[0][7:0]   ;
                        rx_first <= 1'b1                ;
                    end
                    else begin
                        rx_data  <= dphy_data   ;
                        rx_valid <= 1'b1        ;
                    end
                end
                else begin
                    rx_first <= 1'b0        ;
                    rx_data  <= dphy_data   ;
                    rx_valid <= 1'b1        ;
                end
            end
            else begin
                rx_first <= 1'b0    ;
                rx_type  <= 8'hxx   ;
                rx_data  <= 'x      ;
                rx_valid <= 1'b0    ;
            end
        end
    end

    // FIFO
    logic                           fifo_first    ;
    logic                           fifo_black    ;
    logic   [DPHY_LANES-1:0][7:0]   fifo_data     ;
    logic                           fifo_valid    ;
    logic                           fifo_ready    ;
    jelly2_fifo_async_fwtf
            #(
                .DATA_WIDTH     (2 + $bits(rx_data) ),
                .PTR_WIDTH      (8                  ),
                .DOUT_REGS      (1                  ),
                .RAM_TYPE       ("block"            ),
                .S_REGS         (0                  ),
                .M_REGS         (1                  )
            )
        u_fifo_async_fwtf
            (
                .s_reset        (dphy_reset         ),
                .s_clk          (dphy_clk           ),
                .s_cke          (1'b1               ),
                .s_data         ({
                                    rx_first    ,
                                    rx_type[5]  ,   // black
                                    rx_data     
                                }),
                .s_valid        (rx_valid           ),
                .s_ready        (                   ),
                .s_free_count   (                   ),

                .m_reset        (~m_axi4s.aresetn   ),
                .m_clk          (m_axi4s.aclk       ),
                .m_cke          (m_axi4s.aclken     ),
                .m_data         ({
                                    fifo_first  ,
                                    fifo_black  ,
                                    fifo_data   
                                }),
                .m_valid        (fifo_valid         ),
                .m_ready        (fifo_ready         ),
                .m_data_count   (                   )
            );
    
    // width convert
    localparam  type    raw_t = logic [RAW_BITS-1:0];
    logic                   conv_first    ;
    logic                   conv_black    ;
    raw_t   [CHANNELS-1:0]  conv_data     ;
    logic                   conv_valid    ;
    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2                      ),
                .S_NUM              (DPHY_LANES*4           ),
                .M_NUM              (CHANNELS*5             ),
                .HAS_FIRST          (1                      ),
                .HAS_LAST           (0                      ),
                .HAS_STRB           (0                      ),
                .HAS_KEEP           (0                      ),
                .AUTO_FIRST         (0                      ),
                .HAS_ALIGN_S        (0                      ),
                .HAS_ALIGN_M        (0                      ),
                .FIRST_OVERWRITE    (0                      ),
                .FIRST_FORCE_LAST   (0                      ),
                .REDUCE_KEEP        (0                      ),
                .USER_F_WIDTH       (1                      ),
                .USER_L_WIDTH       (0                      ),
                .S_REGS             (1                      ),
                .M_REGS             (1                      )
            )
        u_stream_width_convert
            (
                .reset              (~m_axi4s.aresetn       ),
                .clk                (m_axi4s.aclk           ),
                .cke                (m_axi4s.aclken         ),

                .endian             (1'b0                   ),
                .padding            ('0                     ),
                
                .s_align_s          ('0                     ),
                .s_align_m          ('0                     ),
                .s_first            (fifo_first             ),
                .s_last             (1'b0                   ),
                .s_data             (fifo_data              ),
                .s_strb             ('1                     ),
                .s_keep             ('1                     ),
                .s_user_f           (fifo_black             ),
                .s_user_l           (                       ),
                .s_valid            (fifo_valid             ),
                .s_ready            (fifo_ready             ),

                .m_first            (conv_first             ),
                .m_last             (                       ),
                .m_data             (conv_data              ),
                .m_strb             (                       ),
                .m_keep             (                       ),
                .m_user_f           (conv_black             ),
                .m_user_l           (                       ),
                .m_valid            (conv_valid             ),
                .m_ready            (1'b1                   )
            );


endmodule

`default_nettype wire

// end of file
