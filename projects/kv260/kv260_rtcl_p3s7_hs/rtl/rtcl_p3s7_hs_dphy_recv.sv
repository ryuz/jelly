

`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_hs_dphy_recv
        #(
            parameter   int     X_BITS         = 10                         ,
            parameter   type    x_t            = logic  [X_BITS-1:0]        ,
            parameter   int     Y_BITS         = 10                         ,
            parameter   type    y_t            = logic  [Y_BITS-1:0]        ,

            parameter   int     CHANNELS       = 1                          ,
            parameter   int     RAW_BITS       = 10                         ,
            parameter   int     DPHY_LANES     = 2                          ,
            parameter           DEBUG          = "false"                    
        )
        (
            input   var x_t                             param_black_width   ,
            input   var y_t                             param_black_height  ,
            input   var x_t                             param_image_width   ,
            input   var y_t                             param_image_height  ,

            input   var logic                           dphy_reset          ,
            input   var logic                           dphy_clk            ,
            input   var logic   [DPHY_LANES-1:0][7:0]   dphy_data           ,
            input   var logic                           dphy_valid          ,

            jelly3_axi4s_if.m                           m_axi4s_black       ,
            jelly3_axi4s_if.m                           m_axi4s_image        
        );

    logic       aresetn     ;
    logic       aclk        ;
    logic       aclken      ;
    assign aresetn = m_axi4s_image.aresetn    ;
    assign aclk    = m_axi4s_image.aclk       ;
    assign aclken  = m_axi4s_image.aclken     ;


    // DPHY Receive
    logic                           rx_first    ;
    logic                           rx_last     ;
    logic   [DPHY_LANES-1:0][7:0]   rx_data     ;
    logic                           rx_valid    ;
    always_ff @(posedge dphy_clk) begin
        if ( dphy_reset ) begin
            rx_first <= 1'b1    ;
            rx_data  <= 'x      ;
            rx_valid <= 1'b0    ;
        end
        else begin
            rx_first <= ~rx_valid   ;
            rx_data  <= dphy_data   ;
            rx_valid <= dphy_valid  ;
        end
    end
    assign rx_last = rx_valid & ~dphy_valid;


    // FIFO
    logic                           fifo_first    ;
    logic                           fifo_last     ;
    logic   [DPHY_LANES-1:0][7:0]   fifo_data     ;
    logic                           fifo_valid    ;
    logic                           fifo_ready    ;
    jelly2_fifo_async_fwtf
            #(
                .DATA_WIDTH     (2 + $bits(rx_data) ),
                .PTR_WIDTH      (10                 ),
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
                                    rx_last     ,
                                    rx_data     
                                }),
                .s_valid        (rx_valid           ),
                .s_ready        (                   ),
                .s_free_count   (                   ),

                .m_reset        (~aresetn           ),
                .m_clk          (aclk               ),
                .m_cke          (aclken             ),
                .m_data         ({
                                    fifo_first  ,
                                    fifo_last   ,
                                    fifo_data   
                                }),
                .m_valid        (fifo_valid         ),
                .m_ready        (fifo_ready         ),
                .m_data_count   (                   )
            );

    logic   [31:0]          fifo_count    ;
    always_ff @(posedge aclk) begin
        if ( fifo_valid && fifo_ready ) begin
            if ( fifo_first ) begin
                fifo_count <= 0;
            end
            else begin
                fifo_count <= fifo_count + 1;
            end
        end
    end


    // width convert
    localparam  type    raw_t = logic [RAW_BITS-1:0];
    logic                   conv_first    ;
    logic                   conv_last     ;
    raw_t   [CHANNELS-1:0]  conv_data     ;
    logic                   conv_valid    ;

    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2                      ),
                .S_NUM              (DPHY_LANES*4           ),
                .M_NUM              (CHANNELS*5             ),
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
                .USER_F_WIDTH       (1                      ),
                .USER_L_WIDTH       (0                      ),
                .S_REGS             (1                      ),
                .M_REGS             (1                      )
            )
        u_stream_width_convert
            (
                .reset              (~aresetn               ),
                .clk                (aclk                   ),
                .cke                (aclken                 ),

                .endian             (1'b0                   ),
                .padding            ('0                     ),
                
                .s_align_s          ('0                     ),
                .s_align_m          ('0                     ),
                .s_first            (fifo_first             ),
                .s_last             (fifo_last              ),
                .s_data             (fifo_data              ),
                .s_strb             ('1                     ),
                .s_keep             ('1                     ),
                .s_user_f           ('0                     ),
                .s_user_l           ('0                     ),
                .s_valid            (fifo_valid             ),
                .s_ready            (fifo_ready             ),

                .m_first            (conv_first             ),
                .m_last             (conv_last              ),
                .m_data             (conv_data              ),
                .m_strb             (                       ),
                .m_keep             (                       ),
                .m_user_f           (                       ),
                .m_user_l           (                       ),
                .m_valid            (conv_valid             ),
                .m_ready            (1'b1                   )
            );


    rtcl_p3s7_hs_cnv_axi4s
            #(
                .X_BITS             ($bits(x_t)                 ),
                .x_t                (x_t                        ),
                .Y_BITS             ($bits(y_t)                 ),
                .y_t                (y_t                        ),
                .RAW_BITS           ($bits(raw_t)               ),
                .raw_t              (raw_t                      ),
                .DEBUG              (DEBUG                      )
            )
        u_rtcl_p3s7_hs_cnv_axi4s
            (
                .param_black_width  (param_black_width          ),
                .param_black_height (param_black_height         ),
                .param_image_width  (param_image_width          ),
                .param_image_height (param_image_height         ),
                .s_first            (conv_first                 ),
                .s_last             (conv_last                  ),
                .s_data             (conv_data                  ),
                .s_valid            (conv_valid                 ),
                .m_axi4s_black      (m_axi4s_black              ),
                .m_axi4s_image      (m_axi4s_image              )
            );

endmodule

`default_nettype wire

// end of file
