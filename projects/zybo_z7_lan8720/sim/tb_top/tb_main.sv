// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   X_NUM = 640,   // 3280 / 2,
            parameter   Y_NUM = 480,   // 2464 / 2

            parameter   WB_ADR_WIDTH = 37,
            parameter   WB_DAT_WIDTH = 64,
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
    logic   [7:0]   pmod_a;
    logic   [7:0]   pmod_b;
    logic   [7:0]   pmod_c;
    logic   [7:0]   pmod_d;
    logic   [7:0]   pmod_e;
    logic   [14:0]  DDR_addr;
    logic   [2:0]   DDR_ba;
    logic           DDR_cas_n;
    logic           DDR_ck_n;
    logic           DDR_ck_p;
    logic           DDR_cke;
    logic           DDR_cs_n;
    logic   [3:0]   DDR_dm;
    logic   [31:0]  DDR_dq;
    logic   [3:0]   DDR_dqs_n;
    logic   [3:0]   DDR_dqs_p;
    logic           DDR_odt;
    logic           DDR_ras_n;
    logic           DDR_reset_n;
    logic           DDR_we_n;
    logic           FIXED_IO_ddr_vrn;
    logic           FIXED_IO_ddr_vrp;
    logic   [53:0]  FIXED_IO_mio;
    logic           FIXED_IO_ps_clk;
    logic           FIXED_IO_ps_porb;
    logic           FIXED_IO_ps_srstb;
    
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
        $readmemh("../../data/rx_data.txt", rx_data);
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


//    assign pmod_b[0] = mii0_tx[0];
    assign pmod_b[1] = mii0_rx[1];
    assign pmod_b[2] = mii0_crs;
//    assign pmod_b[3] = mii0_mdc;
//    assign pmod_b[4] = mii0_txen;
    assign pmod_b[5] = mii0_rx[0];
    assign pmod_b[6] = mii0_refclk;
//    assign pmod_b[7] = mii0_mdio;
//    assign pmod_c[0] = mii0_tx[1];



endmodule


`default_nettype wire


// end of file
