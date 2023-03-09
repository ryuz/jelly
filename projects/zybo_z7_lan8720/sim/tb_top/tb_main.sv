// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   WB_ADR_WIDTH = 29,
            parameter   WB_DAT_WIDTH = 32,
            parameter   WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        reset,
            input   wire                        clk50,
            input   wire                        clk100,
            input   wire                        clk200,
            input   wire                        clk250,
    
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_peri_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_peri_sel_i,
            input   wire                        s_wb_peri_we_i,
            input   wire                        s_wb_peri_stb_i,
            output  wire                        s_wb_peri_ack_o
        );
    
    

    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    logic           in_clk125;
    logic   [3:0]   push_sw;
    logic   [3:0]   dip_sw;
    logic   [3:0]   led;

    wire    [7:0]   pmod_a;
    wire    [7:0]   pmod_b;
    wire    [7:0]   pmod_c;
    wire    [7:0]   pmod_d;
    wire    [7:0]   pmod_e;

    wire    [14:0]  DDR_addr;
    wire    [2:0]   DDR_ba;
    wire            DDR_cas_n;
    wire            DDR_ck_n;
    wire            DDR_ck_p;
    wire            DDR_cke;
    wire            DDR_cs_n;
    wire    [3:0]   DDR_dm;
    wire    [31:0]  DDR_dq;
    wire    [3:0]   DDR_dqs_n;
    wire    [3:0]   DDR_dqs_p;
    wire            DDR_odt;
    wire            DDR_ras_n;
    wire            DDR_reset_n;
    wire            DDR_we_n;
    wire            FIXED_IO_ddr_vrn;
    wire            FIXED_IO_ddr_vrp;
    wire    [53:0]  FIXED_IO_mio;
    wire            FIXED_IO_ps_clk;
    wire            FIXED_IO_ps_porb;
    wire            FIXED_IO_ps_srstb;
    
    zybo_z7_lan8720
        i_top
            (
                .in_clk125,
                
                .push_sw,
                .dip_sw,
                .led,

                .pmod_a,
                .pmod_b,
                .pmod_c,
                .pmod_d,
                .pmod_e,
                
                .DDR_addr,
                .DDR_ba,
                .DDR_cas_n,
                .DDR_ck_n,
                .DDR_ck_p,
                .DDR_cke,
                .DDR_cs_n,
                .DDR_dm,
                .DDR_dq,
                .DDR_dqs_n,
                .DDR_dqs_p,
                .DDR_odt,
                .DDR_ras_n,
                .DDR_reset_n,
                .DDR_we_n,
                .FIXED_IO_ddr_vrn,
                .FIXED_IO_ddr_vrp,
                .FIXED_IO_mio,
                .FIXED_IO_ps_clk,
                .FIXED_IO_ps_porb,
                .FIXED_IO_ps_srstb
            );
    

    
    always_comb force i_top.i_design_1.reset  = reset;
    always_comb force i_top.i_design_1.clk100 = clk100;
    always_comb force i_top.i_design_1.clk200 = clk200;
    always_comb force i_top.i_design_1.clk250 = clk250;

//    always_comb force i_top.i_design_1.wb_peri_adr_i = s_wb_peri_adr_i;
//    always_comb force i_top.i_design_1.wb_peri_dat_i = s_wb_peri_dat_i;
//    always_comb force i_top.i_design_1.wb_peri_sel_i = s_wb_peri_sel_i;
//    always_comb force i_top.i_design_1.wb_peri_we_i  = s_wb_peri_we_i;
//    always_comb force i_top.i_design_1.wb_peri_stb_i = s_wb_peri_stb_i;
//    assign s_wb_peri_dat_o = i_top.i_design_1.wb_peri_dat_o;
//    assign s_wb_peri_ack_o = i_top.i_design_1.wb_peri_ack_o;


    // -------------------------
    //  Test Sequence
    // -------------------------

    logic   [2:0]   rx_data     [0:8191];
    initial begin
        $readmemh("../../_data/rx_data.txt", rx_data);
    end

    logic               mii0_refclk;
    logic               mii0_txen;
    logic   [1:0]       mii0_tx;
    logic   [1:0]       mii0_rx;
    logic               mii0_crs;
    logic               mii0_mdc;
    logic               mii0_mdio;

    assign mii0_refclk = clk50;

    logic   [12:0]      rx_count = 0;
    always_ff @(posedge mii0_refclk) begin
        rx_count <= rx_count + 1;
        mii0_crs <= rx_data[rx_count][2];
        mii0_rx  <= rx_data[rx_count][1:0];
    end


//    assign pmod_a[0] = mii0_tx[0];
    assign pmod_a[1] = mii0_rx[1];
    assign pmod_a[2] = mii0_crs;
//    assign pmod_a[3] = mii0_mdc;
//    assign pmod_a[4] = mii0_txen;
    assign pmod_a[5] = mii0_rx[0];
    assign pmod_a[6] = mii0_refclk;
//    assign pmod_a[7] = mii0_mdio;
//    assign pmod_c[0] = mii0_tx[1];

    assign pmod_b[6] = mii0_refclk;
    assign pmod_d[6] = mii0_refclk;
    assign pmod_e[6] = mii0_refclk;

    // loop-back
    assign pmod_b[2] = pmod_a[4]; // crs <- txen
    assign pmod_b[5] = pmod_a[5]; // rx0 <- tx0
    assign pmod_b[1] = pmod_c[0]; // rx1 <- tx1

    assign pmod_d[2] = pmod_b[4]; // crs <- txen
    assign pmod_d[5] = pmod_b[5]; // rx0 <- tx0
    assign pmod_d[1] = pmod_c[1]; // rx1 <- tx1



    // RX
    wire    [3:0]           axi4s_eth_rx_tfirst = i_top.axi4s_eth_rx_tfirst;
    wire    [3:0]           axi4s_eth_rx_tlast  = i_top.axi4s_eth_rx_tlast ;
    wire    [3:0][7:0]      axi4s_eth_rx_tdata  = i_top.axi4s_eth_rx_tdata ;
    wire    [3:0]           axi4s_eth_rx_tvalid = i_top.axi4s_eth_rx_tvalid;
    wire    [3:0]           axi4s_eth_tx_tlast  = i_top.axi4s_eth_tx_tlast ;
    wire    [3:0][7:0]      axi4s_eth_tx_tdata  = i_top.axi4s_eth_tx_tdata ;
    wire    [3:0]           axi4s_eth_tx_tvalid = i_top.axi4s_eth_tx_tvalid;
    wire    [3:0]           axi4s_eth_tx_tready = i_top.axi4s_eth_tx_tready;

    /*
    always_ff @(posedge i_top.mii_refclk[0]) begin
        if ( axi4s_eth_rx_tvalid[0] ) begin
            if ( axi4s_eth_rx_tfirst[0] ) $write("[mii] ");
            $write("%02h ", axi4s_eth_rx_tdata[0]);
            if ( axi4s_eth_rx_tlast[0] ) $display("");
        end
    end
    */
    
    int     ch = 2;
    always_ff @(posedge i_top.mii_refclk[ch]) begin
        if ( axi4s_eth_rx_tvalid[ch] ) begin
            if ( axi4s_eth_rx_tfirst[ch] ) $write("[mii(%1d)] ", ch);
            $write("%02h ", axi4s_eth_rx_tdata[ch]);
            if ( axi4s_eth_rx_tlast[ch] ) $display("");
        end
    end

endmodule


`default_nettype wire


// end of file
