
`timescale 1ns / 1ps
`default_nettype none


module kr260_ether_bridge
        #(
            parameter   DEVICE     = "ULTRASCALE_PLUS"  ,   // デバイス名
            parameter   SIMULATION = "false"            ,   // シミュレーション
            parameter   DEBUG      = "true"                 // デバッグ
        )
        (
            output  var logic           fan_en         ,

            // clock
            input  var logic            in_clk25a       ,
            input  var logic            in_clk25b       ,

            // LED
            output var logic    [1:0]   led             ,

            // Ether0
            output var logic            rgmii0_reset_n  ,
            output var logic            rgmii0_mdc      ,
            inout  tri logic            rgmii0_mdio     ,
            output var logic            rgmii0_gtx_clk  ,
            output var logic            rgmii0_tx_ctrl  ,
            output var logic    [3:0]   rgmii0_tx_d     ,
            input  var logic            rgmii0_rx_clk   ,
            input  var logic            rgmii0_rx_ctrl  ,
            input  var logic    [3:0]   rgmii0_rx_d     ,
            input  var logic    [2:0]   rgmii0_led      ,

            // Ether1
            output var logic            rgmii1_reset_n  ,
            output var logic            rgmii1_mdc      ,
            inout  tri logic            rgmii1_mdio     ,
            output var logic            rgmii1_gtx_clk  ,
            output var logic            rgmii1_tx_ctrl  ,
            output var logic    [3:0]   rgmii1_tx_d     ,
            input  var logic            rgmii1_rx_clk   ,
            input  var logic            rgmii1_rx_ctrl  ,
            input  var logic    [3:0]   rgmii1_rx_d     ,
            input  var logic    [2:0]   rgmii1_led      
        );


    // ------------------------------
    //  ZynqMP
    // ------------------------------

    logic           ether_reset     ;
    logic           ether_clk       ;
    
    design_1
        u_design_1
            (
                .fan_en                 (fan_en         ),

                .in_clk25               (in_clk25a      ),

                .ether_reset            (ether_reset    ),
                .ether_clk              (ether_clk      )
            );


    // ------------------------------
    //  Giga-Ether RGMII Interface
    // ------------------------------

    localparam RX_DDR_CLK_EDGE = "SAME_EDGE_PIPELINED";
//  localparam RX_DDR_CLK_EDGE   = "SAME_EDGE";
    localparam RX_IS_CB_INVERTED = 1'b1;
    localparam RX_IS_C_INVERTED  = 1'b0;
    localparam TX_IS_C_INVERTED  = 1'b0;
    localparam TX_IS_D1_INVERTED = 1'b0;
    localparam TX_IS_D2_INVERTED = 1'b0;

    logic           rgmii0_rx_clk_buf   ;
    logic           rgmii1_rx_clk_buf   ;
    logic   [1:0]   ether0_rx_ctl       ;
    logic   [7:0]   ether0_rx_d         ;
    logic   [1:0]   ether1_rx_ctl       ;
    logic   [7:0]   ether1_rx_d         ;




    // ------------------------------
    //  RGMII0
    // ------------------------------

    // RGMII0
    assign rgmii0_reset_n = ~ether_reset;
    assign rgmii0_mdc     = 1'b0;
    assign rgmii0_mdio    = 1'bz;

    // RGMII0 rx
    BUFG
        u_bufg_rgmii0_rx_clk
            (
                .I      (rgmii0_rx_clk      ),
                .O      (rgmii0_rx_clk_buf  )
            );
    
    IDDRE1
            #(
                .DDR_CLK_EDGE   (RX_DDR_CLK_EDGE    ),
                .IS_CB_INVERTED (RX_IS_CB_INVERTED  ),
                .IS_C_INVERTED  (RX_IS_C_INVERTED   ) 
            )
        u_iddre1_rgmii0_rx_ctl
            (
                .Q1             (ether0_rx_ctl[0]   ),
                .Q2             (ether0_rx_ctl[1]   ),
                .C              (rgmii0_rx_clk_buf  ),  
                .CB             (rgmii0_rx_clk_buf  ),
                .D              (rgmii0_rx_ctrl     ),  
                .R              (1'b0               )   
            );
    
    for ( genvar i = 0; i < 4; i++ ) begin : rx_iddre1_rgmii0
        IDDRE1
                #(
                    .DDR_CLK_EDGE   (RX_DDR_CLK_EDGE    ),
                    .IS_CB_INVERTED (RX_IS_CB_INVERTED  ),
                    .IS_C_INVERTED  (RX_IS_C_INVERTED   ) 
                )
            u_iddre1_rgmii0_rx_d
                (
                    .Q1             (ether0_rx_d[i+0]   ),
                    .Q2             (ether0_rx_d[i+4]   ),
                    .C              (rgmii0_rx_clk_buf  ),  
                    .CB             (rgmii0_rx_clk_buf  ),
                    .D              (rgmii0_rx_d[i]     ),  
                    .R              (1'b0               )   
                );
    end

    // RGMII0 tx
    logic   rgmii0_tx_clk;
    assign rgmii0_tx_clk = rgmii1_rx_clk_buf;

    ODDRE1
            #(
                .IS_C_INVERTED  (1'b0               ),
                .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                .SIM_DEVICE     (DEVICE             ),
                .SRVAL          (1'b0               )
            )
        u_oddre1_tx_rgmii0_tx_clk
            (
                .Q              (rgmii0_gtx_clk     ),
                .C              (rgmii0_tx_clk      ),
                .D1             (1'b1               ),
                .D2             (1'b0               ),
                .SR             (1'b0               )
            );

    ODDRE1
            #(
                .IS_C_INVERTED  (TX_IS_C_INVERTED   ),
                .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                .SIM_DEVICE     (DEVICE             ),
                .SRVAL          (1'b0               )
            )
        u_oddre0_tx_d 
            (
                .Q              (rgmii0_tx_ctrl     ),
                .C              (rgmii0_tx_clk      ),
                .D1             (ether1_rx_ctl[0]   ),
                .D2             (ether1_rx_ctl[1]   ),
                .SR             (ether_reset        )
            );    
    
    for ( genvar i = 0; i < 4; i++ ) begin : tx_oddre1_rgmii0
        ODDRE1
                #(
                    .IS_C_INVERTED  (TX_IS_C_INVERTED   ),
                    .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                    .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                    .SIM_DEVICE     (DEVICE             ),
                    .SRVAL          (1'b0               )
                )
            u_oddre0_tx_d 
                (
                    .Q              (rgmii0_tx_d[i]     ),
                    .C              (rgmii0_tx_clk      ),
                    .D1             (ether1_rx_d[i+0]   ),
                    .D2             (ether1_rx_d[i+4]   ),
                    .SR             (ether_reset        )
                );
    end



    // ------------------------------
    //  RGMII1
    // ------------------------------

    assign rgmii1_reset_n = ~ether_reset;
    assign rgmii1_mdc     = 1'b0;
    assign rgmii1_mdio    = 1'bz;

    // RGMII0 rx
    BUFG
        u_bufg_rgmii1_rx_clk
            (
                .I      (rgmii1_rx_clk      ),
                .O      (rgmii1_rx_clk_buf  )
            );
    
    IDDRE1
            #(
                .DDR_CLK_EDGE   (RX_DDR_CLK_EDGE    ),
                .IS_CB_INVERTED (RX_IS_CB_INVERTED  ),
                .IS_C_INVERTED  (RX_IS_C_INVERTED   ) 
            )
        u_iddre1_rgmii1_rx_ctl
            (
                .Q1             (ether1_rx_ctl[0]   ),
                .Q2             (ether1_rx_ctl[1]   ),
                .C              (rgmii1_rx_clk_buf  ),  
                .CB             (rgmii1_rx_clk_buf  ),
                .D              (rgmii1_rx_ctrl     ),  
                .R              (1'b0               )   
            );
    
    for ( genvar i = 0; i < 4; i++ ) begin : rx_iddre1_rgmii1
        IDDRE1
                #(
                    .DDR_CLK_EDGE   (RX_DDR_CLK_EDGE    ),
                    .IS_CB_INVERTED (RX_IS_CB_INVERTED  ),
                    .IS_C_INVERTED  (RX_IS_C_INVERTED   ) 
                )
            u_iddre1_rgmii1_rx_d
                (
                    .Q1             (ether1_rx_d[i+0]   ),
                    .Q2             (ether1_rx_d[i+4]   ),
                    .C              (rgmii1_rx_clk_buf  ),  
                    .CB             (rgmii1_rx_clk_buf  ),
                    .D              (rgmii1_rx_d[i]     ),  
                    .R              (1'b0               )   
                );
    end


    // RGMII1 tx
    logic   rgmii1_tx_clk;
    assign rgmii1_tx_clk = rgmii0_rx_clk_buf;

    ODDRE1
            #(
                .IS_C_INVERTED  (1'b0               ),
                .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                .SIM_DEVICE     (DEVICE             ),
                .SRVAL          (1'b0               )
            )
        u_oddre1_tx_rgmii1_tx_clk
            (
                .Q              (rgmii1_gtx_clk     ),
                .C              (rgmii1_tx_clk      ),
                .D1             (1'b1               ),
                .D2             (1'b0               ),
                .SR             (1'b0               )
            );

    ODDRE1
            #(
                .IS_C_INVERTED  (TX_IS_C_INVERTED   ),
                .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                .SIM_DEVICE     (DEVICE             ),
                .SRVAL          (1'b0               )
            )
        u_oddre1_tx_d 
            (
                .Q              (rgmii1_tx_ctrl     ),
                .C              (rgmii1_tx_clk      ),
                .D1             (ether0_rx_ctl[0]   ),
                .D2             (ether0_rx_ctl[1]   ),
                .SR             (ether_reset        )
            );    
    
    for ( genvar i = 0; i < 4; i++ ) begin : tx_oddre1_rgmii1
        ODDRE1
                #(
                    .IS_C_INVERTED  (TX_IS_C_INVERTED   ),
                    .IS_D1_INVERTED (TX_IS_D1_INVERTED  ),
                    .IS_D2_INVERTED (TX_IS_D2_INVERTED  ),
                    .SIM_DEVICE     (DEVICE             ),
                    .SRVAL          (1'b0               )
                )
            u_oddre1_tx_d 
                (
                    .Q              (rgmii1_tx_d[i]     ),
                    .C              (rgmii1_tx_clk      ),
                    .D1             (ether0_rx_d[i+0]   ),
                    .D2             (ether0_rx_d[i+4]   ),
                    .SR             (ether_reset        )
                );
    end


    // ------------------------------
    //  LED
    // ------------------------------

    logic  [23:0]   counter0 = 0;
    always @(posedge rgmii0_rx_clk_buf) begin
        counter0 <= counter0 + 1;
    end

    logic  [23:0]   counter1 = 0;
    always @(posedge rgmii1_rx_clk_buf) begin
        counter1 <= counter1 + 1;
    end

//    logic  [23:0]   counter2 = 0;
//    always @(posedge ether_clk) begin
//        counter2 <= counter2 + 1;
//    end
    
    assign led[0] = counter0[23];
    assign led[1] = counter1[23];



    // ------------------------------
    //  Debug
    // ------------------------------

    (* mark_debug = "true" *) logic   [1:0]     dbg_ether0_rx_ctl;
    (* mark_debug = "true" *) logic   [7:0]     dbg_ether0_rx_d  ;
    always @(posedge rgmii0_rx_clk_buf) begin
        dbg_ether0_rx_ctl <= ether0_rx_ctl;
        dbg_ether0_rx_d   <= ether0_rx_d  ;
    end

    
    (* mark_debug = "true" *) logic   [1:0]     dbg_ether1_rx_ctl;
    (* mark_debug = "true" *) logic   [7:0]     dbg_ether1_rx_d  ;
    always @(posedge rgmii1_rx_clk) begin
        dbg_ether1_rx_ctl <= ether1_rx_ctl;
        dbg_ether1_rx_d   <= ether1_rx_d  ;
    end

endmodule


`default_nettype wire

