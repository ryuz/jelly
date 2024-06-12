// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
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
            input   wire                        clk125,
            input   wire                        clk200,
            input   wire                        clk250,

            input   wire                        dmy_reset,
            input   wire                        dmy_clk50,
            input   wire                        dmy_clk100,
            input   wire                        dmy_clk125,
            input   wire                        dmy_clk200,
            input   wire                        dmy_clk250,


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
    logic   [3:0]   push_sw = '0;
    logic   [3:0]   dip_sw = 4'b0010;
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
    
    assign in_clk125 = clk125;

    zybo_necolink_lan8720
            #(
                .DEBUG              (1'b1),
                .SIMULATION         (1'b1)
            )
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
    always_comb force i_top.i_design_1.clk125 = clk125;
    always_comb force i_top.i_design_1.clk200 = clk200;
    always_comb force i_top.i_design_1.clk250 = clk250;

//    always_comb force i_top.i_design_1.wb_peri_adr_i = s_wb_peri_adr_i;
//    always_comb force i_top.i_design_1.wb_peri_dat_i = s_wb_peri_dat_i;
//    always_comb force i_top.i_design_1.wb_peri_sel_i = s_wb_peri_sel_i;
//    always_comb force i_top.i_design_1.wb_peri_we_i  = s_wb_peri_we_i;
//    always_comb force i_top.i_design_1.wb_peri_stb_i = s_wb_peri_stb_i;
//    assign s_wb_peri_dat_o = i_top.i_design_1.wb_peri_dat_o;
//    assign s_wb_peri_ack_o = i_top.i_design_1.wb_peri_ack_o;



    wire    [7:0]   dmy_pmod_a;
    wire    [7:0]   dmy_pmod_b;
    wire    [7:0]   dmy_pmod_c;
    wire    [7:0]   dmy_pmod_d;
    wire    [7:0]   dmy_pmod_e;

    zybo_necolink_lan8720
            #(
                .DEBUG              (1'b1),
                .SIMULATION         (1'b1)
            )
        i_top_dmy
            (
                .in_clk125          (dmy_clk125),
                
                .push_sw            (4'b0000),
                .dip_sw             (4'b0010),
                .led                (),

                .pmod_a             (dmy_pmod_a),
                .pmod_b             (dmy_pmod_b),
                .pmod_c             (dmy_pmod_c),
                .pmod_d             (dmy_pmod_d),
                .pmod_e             (dmy_pmod_e),
                
                .DDR_addr           (),
                .DDR_ba             (),
                .DDR_cas_n          (),
                .DDR_ck_n           (),
                .DDR_ck_p           (),
                .DDR_cke            (),
                .DDR_cs_n           (),
                .DDR_dm             (),
                .DDR_dq             (),
                .DDR_dqs_n          (),
                .DDR_dqs_p          (),
                .DDR_odt            (),
                .DDR_ras_n          (),
                .DDR_reset_n        (),
                .DDR_we_n           (),
                .FIXED_IO_ddr_vrn   (),
                .FIXED_IO_ddr_vrp   (),
                .FIXED_IO_mio       (),
                .FIXED_IO_ps_clk    (),
                .FIXED_IO_ps_porb   (),
                .FIXED_IO_ps_srstb  ()
            );
    
    always_comb force i_top_dmy.i_design_1.reset  = dmy_reset;
    always_comb force i_top_dmy.i_design_1.clk100 = dmy_clk100;
    always_comb force i_top_dmy.i_design_1.clk125 = dmy_clk125;
    always_comb force i_top_dmy.i_design_1.clk200 = dmy_clk200;
    always_comb force i_top_dmy.i_design_1.clk250 = dmy_clk250;


    logic               correct_reset;
    logic               correct_clk;
    logic   [23:0]      current_time;
    logic   [23:0]      correct_time;
    logic               correct_renew;
    logic               correct_valid;
//    assign correct_reset    = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.reset   ;
//    assign correct_clk      = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.clk   ;
//    assign current_time     = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.current_time    ;
//    assign correct_time     = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.correct_time    ;
//    assign correct_renew    = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.correct_renew;
//    assign correct_valid    = i_top_dmy.i_etherneco_slave.u_etherneco_synctimer_slave.u_synctimer_core.u_synctimer_adjuster.correct_valid   ;

    int fp;
    initial begin
        fp = $fopen("_correct.csv", "w");
        $fwrite(fp, "current_time,correct_time,renew\n");
    end
    always_ff @(posedge correct_clk) begin
        if ( correct_reset ) begin
        end
        else begin
            if ( correct_valid ) begin
                $fwrite(fp, "%d,%d,%d\n", current_time, correct_time, correct_renew);
            end
        end
    end


    // -------------------------
    //  Test Sequence
    // -------------------------

    // test data
    logic   [2:0]   rx_data     [0:8191];
    initial begin
        $readmemh("../../_data/rx_data.txt", rx_data);
    end

    logic   [12:0]      rx_count = 0;
    logic               mii_crs;
    logic   [1:0]       mii_rx;
    always_ff @(posedge clk50) begin
        rx_count <= rx_count + 1;
        mii_crs <= rx_data[rx_count][2];
        mii_rx  <= rx_data[rx_count][1:0];
    end

    // -------------------------
    //  ring connection
    // -------------------------

    // pmod_a : master : up
    // pmod_b : master : down
    // pmod_d : slave0 : up
    // pmod_e : slave0 : down

    // refclk
    assign pmod_a[6] = clk50;
    assign pmod_b[6] = clk50;
    assign pmod_d[6] = clk50;
    assign pmod_e[6] = clk50;

    assign dmy_pmod_a[6] = clk50;
    assign dmy_pmod_b[6] = clk50;
    assign dmy_pmod_d[6] = clk50;
    assign dmy_pmod_e[6] = clk50;


    // pmod_b <-> pmod_d
    assign pmod_d[2] = pmod_b[4]; // crs <- txen
    assign pmod_d[5] = pmod_b[0]; // rx0 <- tx0
    assign pmod_d[1] = pmod_c[1]; // rx1 <- tx1

    assign pmod_b[2] = pmod_d[4]; // crs <- txen
    assign pmod_b[5] = pmod_d[0]; // rx0 <- tx0
    assign pmod_b[1] = pmod_c[2]; // rx1 <- tx1

    // pmod_a <-> pmod_e
//    assign pmod_e[2] = pmod_a[4]; // crs <- txen
//    assign pmod_e[5] = pmod_a[0]; // rx0 <- tx0
//    assign pmod_e[1] = pmod_c[0]; // rx1 <- tx1
    
//    assign pmod_a[2] = pmod_e[4]; // crs <- txen
//    assign pmod_a[5] = pmod_e[0]; // rx0 <- tx0
//    assign pmod_a[1] = pmod_c[3]; // rx1 <- tx1

//    assign pmod_a[2] = mii_crs;
//    assign pmod_a[5] = mii_rx[0];
//    assign pmod_a[1] = mii_rx[1];

    assign dmy_pmod_d[2] = pmod_e[4]; // crs <- txen
    assign dmy_pmod_d[5] = pmod_e[0]; // rx0 <- tx0
    assign dmy_pmod_d[1] = pmod_c[3]; // rx1 <- tx1

    assign pmod_e[2] = dmy_pmod_d[4]; // crs <- txen
    assign pmod_e[5] = dmy_pmod_d[0]; // rx0 <- tx0
    assign pmod_e[1] = dmy_pmod_c[2]; // rx1 <- tx1

    //
    assign pmod_a[2] = dmy_pmod_e[4]; // crs <- txen
    assign pmod_a[5] = dmy_pmod_e[0]; // rx0 <- tx0
    assign pmod_a[1] = dmy_pmod_c[3]; // rx1 <- tx1

    assign dmy_pmod_e[2] = pmod_a[4]; // crs <- txen
    assign dmy_pmod_e[5] = pmod_a[0]; // rx0 <- tx0
    assign dmy_pmod_e[1] = pmod_c[0]; // rx1 <- tx1



    // RX
    wire    [7:0]           axi4s_eth_rx_tfirst = {i_top_dmy.axi4s_eth_rx_tfirst, i_top.axi4s_eth_rx_tfirst};
    wire    [7:0]           axi4s_eth_rx_tlast  = {i_top_dmy.axi4s_eth_rx_tlast , i_top.axi4s_eth_rx_tlast };
    wire    [7:0][7:0]      axi4s_eth_rx_tdata  = {i_top_dmy.axi4s_eth_rx_tdata , i_top.axi4s_eth_rx_tdata };
    wire    [7:0]           axi4s_eth_rx_tvalid = {i_top_dmy.axi4s_eth_rx_tvalid, i_top.axi4s_eth_rx_tvalid};
    wire    [7:0]           axi4s_eth_tx_tfirst = {i_top_dmy.axi4s_eth_tx_tfirst, i_top.axi4s_eth_tx_tfirst};
    wire    [7:0]           axi4s_eth_tx_tlast  = {i_top_dmy.axi4s_eth_tx_tlast , i_top.axi4s_eth_tx_tlast };
    wire    [7:0][7:0]      axi4s_eth_tx_tdata  = {i_top_dmy.axi4s_eth_tx_tdata , i_top.axi4s_eth_tx_tdata };
    wire    [7:0]           axi4s_eth_tx_tvalid = {i_top_dmy.axi4s_eth_tx_tvalid, i_top.axi4s_eth_tx_tvalid};
    wire    [7:0]           axi4s_eth_tx_tready = {i_top_dmy.axi4s_eth_tx_tready, i_top.axi4s_eth_tx_tready};

    /*
    always_ff @(posedge i_top.mii_refclk[0]) begin
        if ( axi4s_eth_rx_tvalid[0] ) begin
            if ( axi4s_eth_rx_tfirst[0] ) $write("[mii] ");
            $write("%02h ", axi4s_eth_rx_tdata[0]);
            if ( axi4s_eth_rx_tlast[0] ) $display("");
        end
    end
    */
    
    int     ch = 1;
//    int     ch = 0;
    always_ff @(posedge i_top.aclk) begin
        if ( ~i_top.aresetn ) begin
        end
        else begin
            if ( axi4s_eth_rx_tvalid[ch] ) begin
                if ( axi4s_eth_rx_tfirst[ch] ) $write("[mii(%1d)] ", ch);
                $write("%02h ", axi4s_eth_rx_tdata[ch]);
                if ( axi4s_eth_rx_tlast[ch] ) $display("");
            end
        end
    end


    int fp_tx[8];
    int fp_rx[8];
    initial begin
        fp_tx[0] = $fopen("phy_tx0_log.txt", "w");
        fp_tx[1] = $fopen("phy_tx1_log.txt", "w");
        fp_tx[2] = $fopen("phy_tx2_log.txt", "w");
        fp_tx[3] = $fopen("phy_tx3_log.txt", "w");
        fp_rx[0] = $fopen("phy_rx0_log.txt", "w");
        fp_rx[1] = $fopen("phy_rx1_log.txt", "w");
        fp_rx[2] = $fopen("phy_rx2_log.txt", "w");
        fp_rx[3] = $fopen("phy_rx3_log.txt", "w");

        fp_tx[4] = $fopen("phy_dmy_tx0_log.txt", "w");
        fp_tx[5] = $fopen("phy_dmy_tx1_log.txt", "w");
        fp_tx[6] = $fopen("phy_dmy_tx2_log.txt", "w");
        fp_tx[7] = $fopen("phy_dmy_tx3_log.txt", "w");
        fp_rx[4] = $fopen("phy_dmy_rx0_log.txt", "w");
        fp_rx[5] = $fopen("phy_dmy_rx1_log.txt", "w");
        fp_rx[6] = $fopen("phy_dmy_rx2_log.txt", "w");
        fp_rx[7] = $fopen("phy_dmy_rx3_log.txt", "w");
    end
    always_ff @(posedge i_top.aclk) begin
        if ( ~i_top.aresetn ) begin
        end
        else begin
            for ( int i = 0; i < 8; ++i ) begin
                if ( axi4s_eth_tx_tvalid[i] && axi4s_eth_tx_tready[i] ) begin
                    if ( axi4s_eth_tx_tfirst[i] ) $fwrite(fp_tx[i], "[mii(%1d)] ", i);
                    $fwrite(fp_tx[i], "%02h ", axi4s_eth_tx_tdata[i]);
                    if ( axi4s_eth_tx_tlast[i] ) $fdisplay(fp_tx[i], "");
                end

                if ( axi4s_eth_rx_tvalid[i] ) begin
                    if ( axi4s_eth_rx_tfirst[i] ) $fwrite(fp_rx[i], "[mii(%1d)] ", i);
                    $fwrite(fp_rx[i], "%02h ", axi4s_eth_rx_tdata[i]);
                    if ( axi4s_eth_rx_tlast[i] ) $fdisplay(fp_rx[i], "");
                end
            end
        end
    end



endmodule


`default_nettype wire


// end of file
