// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_lan8720_ila
        #(
            parameter bit DEBUG      = 1'b1,
            parameter bit SIMULATION = 1'b0
        )
        (
            input   var logic            in_clk125  ,
            input   var logic    [3:0]   push_sw    ,
            input   var logic    [3:0]   dip_sw     ,
            output  var logic    [3:0]   led        ,

            inout   tri logic    [7:0]   pmod_a     ,
            inout   tri logic    [7:0]   pmod_b     ,
            inout   tri logic    [7:0]   pmod_c     ,
            inout   tri logic    [7:0]   pmod_d     ,
            inout   tri logic    [7:0]   pmod_e     
        );
    

    // ---------------------------------
    // 100BASE-TX Ether (RMII)
    // ---------------------------------

    logic   [1:0]       rmii_refclk ;
    logic   [1:0]       rmii_txen   ;
    logic   [1:0][1:0]  rmii_tx     ;
    logic   [1:0][1:0]  rmii_rx     ;
    logic   [1:0]       rmii_crs    ;
    logic   [1:0]       rmii_mdc    ;
    logic   [1:0]       rmii_mdio_t ;
    logic   [1:0]       rmii_mdio_i ;
    logic   [1:0]       rmii_mdio_o ;

    rmii_to_pmod
        u_rmii_to_pmod
            (
                .rmii_refclk    ,
                .rmii_txen      ,
                .rmii_tx        ,
                .rmii_rx        ,
                .rmii_crs       ,
                .rmii_mdc       ,
                .rmii_mdio_t    ,
                .rmii_mdio_i    ,
                .rmii_mdio_o    ,

                .pmod_a         ,
                .pmod_b         ,
                .pmod_c         
//              .pmod_d         ,
//              .pmod_e         
            );


    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_rx_tfirst ;
    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_rx_tlast  ;
    (* mark_debug="true" *) logic   [1:0][7:0]      axi4s_eth_rx_tdata  ;
    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_rx_tvalid ;
                            logic   [1:0]           axi4s_eth_tx_tfirst ;
    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_tx_tlast  ;
    (* mark_debug="true" *) logic   [1:0][7:0]      axi4s_eth_tx_tdata  ;
    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_tx_tvalid ;
    (* mark_debug="true" *) logic   [1:0]           axi4s_eth_tx_tready ;

    wire    aresetn = 1'b1      ;
    wire    aclk    = in_clk125 ;
    
    generate
    for ( genvar i = 0; i < 2; i++ ) begin : loop_rmii_phy
        rmii_phy
                #(
                    .DEBUG              ("true")
                )
            u_rmii_phy
                (
                    .aresetn            (aresetn                ),
                    .aclk               (aclk                   ),

                    .m_axi4s_rx_tfirst  (axi4s_eth_rx_tfirst[i] ),
                    .m_axi4s_rx_tlast   (axi4s_eth_rx_tlast [i] ),
                    .m_axi4s_rx_tdata   (axi4s_eth_rx_tdata [i] ),
                    .m_axi4s_rx_tvalid  (axi4s_eth_rx_tvalid[i] ),

                    .s_axi4s_tx_tlast   (axi4s_eth_tx_tlast [i] ),
                    .s_axi4s_tx_tdata   (axi4s_eth_tx_tdata [i] ),
                    .s_axi4s_tx_tvalid  (axi4s_eth_tx_tvalid[i] ),
                    .s_axi4s_tx_tready  (axi4s_eth_tx_tready[i] ),
                    
                    .rmii_refclk        (rmii_refclk[i]         ),
                    .rmii_txen          (rmii_txen  [i]         ),
                    .rmii_tx            (rmii_tx    [i]         ),
                    .rmii_rx            (rmii_rx    [i]         ),
                    .rmii_crs           (rmii_crs   [i]         ),
                    .rmii_mdc           (rmii_mdc   [i]         ),
                    .rmii_mdio_t        (rmii_mdio_t[i]         ),
                    .rmii_mdio_o        (rmii_mdio_o[i]         ),
                    .rmii_mdio_i        (rmii_mdio_i[i]         )
                );
    end
    endgenerate

    assign axi4s_eth_tx_tlast [0] = axi4s_eth_rx_tlast [1];
    assign axi4s_eth_tx_tdata [0] = axi4s_eth_rx_tdata [1];
    assign axi4s_eth_tx_tvalid[0] = axi4s_eth_rx_tvalid[1];

    assign axi4s_eth_tx_tlast [1] = axi4s_eth_rx_tlast [0];
    assign axi4s_eth_tx_tdata [1] = axi4s_eth_rx_tdata [0];
    assign axi4s_eth_tx_tvalid[1] = axi4s_eth_rx_tvalid[0];

    (* mark_debug="true" *) logic              tx_last  ;
    (* mark_debug="true" *) logic   [7:0]      tx_data  ;
    (* mark_debug="true" *) logic              tx_en    ;
    (* mark_debug="true" *) logic              rx_last  ;
    (* mark_debug="true" *) logic   [7:0]      rx_data  ;
    (* mark_debug="true" *) logic              rx_en    ;
    assign tx_last = axi4s_eth_rx_tlast [1] ;
    assign tx_data = axi4s_eth_rx_tdata [1] ;
    assign tx_en   = axi4s_eth_rx_tvalid[1] ;
    assign rx_last = axi4s_eth_rx_tlast [0] ;
    assign rx_data = axi4s_eth_rx_tdata [0] ;
    assign rx_en   = axi4s_eth_rx_tvalid[0] ;


    // TX CRC
    (* mark_debug="true" *) logic           tx_crc_end    ;
    (* mark_debug="true" *) logic           tx_crc_start  ;
    (* mark_debug="true" *) logic           tx_crc_update ;
    (* mark_debug="true" *) logic   [31:0]  tx_crc_value  ;
    (* mark_debug="true" *) logic           tx_crc_match  ;
    (* mark_debug="true" *) logic           tx_crc_error  ;
    always_ff @(posedge aclk) begin
        if ( tx_en ) begin
            tx_crc_start <= (tx_data == 8'hd5);
            if ( tx_last ) begin
                tx_crc_update <= 1'b0;
            end
            else if ( tx_crc_start ) begin
                tx_crc_update <= 1'b1;
            end
        end
        tx_crc_end <= tx_en && tx_last;
    end

    jelly2_calc_crc
            #(
                .DATA_WIDTH     (8              ),
                .CRC_WIDTH      (32             ),
                .POLY_REPS      (32'h04C11DB7   ),  // Polynomial representations
                .REVERSED       (0              )
            )
        u_calc_crc_tx
            (
                .reset          (~aresetn       ),
                .clk            (aclk           ),
                .cke            (1'b1           ),
                
                .in_update      (tx_crc_update  ),
                .in_data        (tx_data        ),
                .in_valid       (tx_en          ),
                
                .out_crc        (tx_crc_value   )
            );
    assign tx_crc_match = (tx_crc_value == 32'h2144df1c);
    assign tx_crc_error = tx_crc_end && (tx_crc_value != 32'h2144df1c);


    // RX CRC
    (* mark_debug="true" *) logic           rx_crc_end    ;
    (* mark_debug="true" *) logic           rx_crc_start  ;
    (* mark_debug="true" *) logic           rx_crc_update ;
    (* mark_debug="true" *) logic   [31:0]  rx_crc_value  ;
    (* mark_debug="true" *) logic           rx_crc_match  ;
    (* mark_debug="true" *) logic           rx_crc_error  ;
    always_ff @(posedge aclk) begin
        if ( rx_en ) begin
            rx_crc_start <= (rx_data == 8'hd5);
            if ( rx_last ) begin
                rx_crc_update <= 1'b0;
            end
            else if ( rx_crc_start ) begin
                rx_crc_update <= 1'b1;
            end
        end
        rx_crc_end <= rx_en && rx_last;
    end

    jelly2_calc_crc
            #(
                .DATA_WIDTH     (8              ),
                .CRC_WIDTH      (32             ),
                .POLY_REPS      (32'h04C11DB7   ),  // Polynomial representations
                .REVERSED       (0              )
            )
        u_calc_crc_rx
            (
                .reset          (~aresetn       ),
                .clk            (aclk           ),
                .cke            (1'b1           ),
                
                .in_update      (rx_crc_update  ),
                .in_data        (rx_data        ),
                .in_valid       (rx_en          ),
                
                .out_crc        (rx_crc_value   )
            );
    assign rx_crc_match = (rx_crc_value == 32'h2144df1c);
    assign rx_crc_error = rx_crc_end && (rx_crc_value != 32'h2144df1c);




    assign led[0] = dip_sw[0];
    assign led[1] = dip_sw[1];

//    assign led[0] = reg_counter_clk200[24];
//    assign led[1] = reg_counter_clk100[24];
//    assign led[2] = reg_counter_mii0_clk[23];
//    assign led[3] = reg_counter_mii1_clk[23];
    

endmodule


`default_nettype wire

