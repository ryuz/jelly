
`timescale 1ns / 1ps
`default_nettype none


module tb_mipi_raw10();
    
    initial begin
        $dumpfile("tb_mipi_raw10.vcd");
        $dumpvars(0, tb_mipi_raw10);
    
    #1000000
        $finish;
    end
    

    // -----------------------------
    //  reset & clock
    // -----------------------------

    localparam RATE_200  = 1000.0/200.0;
    localparam RATE_DPHY = 1000.0/114.0;

    logic   reset = 1'b1;
    initial #(RATE_200*100)  reset = 1'b0;

    logic   clk200 = 1'b1;
    initial forever #(RATE_200/2.0)     clk200 = ~clk200;
    
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


    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (10                 )
            )
        axi4s_tx_raw10
            (
                .aresetn        (~reset             ),
                .aclk           (clk200             ),
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
                .aresetn        (~reset             ),
                .aclk           (clk200             ),
                .aclken         (1'b1               )
            );

    jelly3_mipi_csi_tx_raw10_to_2byte
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi_tx_raw10_to_2byte
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
                .LOW_DEALY      (0                  ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo_tx
            (
                .s_axi4s        (axi4s_tx_2byte.s   ),
                .m_axi4s        (axi4s_tx_fifo.m    ),

                .s_free_count   (                   ),
                .m_data_count   (                   )
            );

    // mipi_csi_tx_gen_2lane
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
    


    logic   [7:0]   param_type  ;
    logic   [15:0]  param_wc    ;
    assign param_type = 8'h2b;  // RAW10
    assign param_wc   = 16'(IMG_WIDTH * 10 / 8);
    jelly3_mipi_csi_tx_packet_2lane
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi_tx_packet_2lane
            (
                .param_type      ,
                .param_wc        ,

                .frame_start     (tx_frame_start    ),
                .frame_end       (1'b0              ),

                .s_axi4s         (axi4s_tx_fifo.s   ),
                .m_axi4s         (axi4s_tx_dphy.m   )
            );

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


endmodule


`default_nettype wire


// end of file
