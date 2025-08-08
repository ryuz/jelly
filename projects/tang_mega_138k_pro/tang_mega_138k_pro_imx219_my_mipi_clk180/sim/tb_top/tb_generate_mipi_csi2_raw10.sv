
`timescale 1ns / 1ps
`default_nettype none


module tb_generate_mipi_csi2_raw10
        #(
            parameter  int     IMG_WIDTH   = 640        ,
            parameter  int     IMG_HEIGHT  = 480        ,
            parameter  int     H_BLANK     = 256        ,
            parameter  int     V_BLANK     = 16         ,
            parameter          DEVICE      = "RTL"      ,
            parameter          SIMULATION  = "true"     ,
            parameter          DEBUG       = "false"    
        )
        (
            input   var logic               reset           ,
            input   var logic               cam_clk         ,
            input   var logic               dphy_clk        ,

            output  var logic   [1:0][7:0]  dphy_tx_datahs  ,
            output  var logic               dphy_tx_validhs ,
            output  var logic               dphy_tx_readyhs 
        );

    // -----------------------------
    //  master RAW10
    // -----------------------------

    wire    logic   tx_cam_reset = reset    ;
    wire    logic   tx_cam_clk   = cam_clk  ;

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

endmodule


`default_nettype wire


// end of file
