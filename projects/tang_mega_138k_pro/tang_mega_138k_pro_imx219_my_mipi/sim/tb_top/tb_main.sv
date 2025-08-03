
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic       reset       ,
            input   var logic       sys_clk     ,
            input   var logic       dphy_clk    ,
            input   var logic       cam_clk     ,
            input   var logic       dvi_clk     
        );


    // -----------------------------
    //  top
    // -----------------------------

    logic           in_reset        ;
    logic           in_clk50        ;
    logic           uart_rx         ;
    logic           uart_tx         ;
    wire            mipi0_clk_p     ;
    wire            mipi0_clk_n     ;
    wire    [1:0]   mipi0_data_p    ;
    wire    [1:0]   mipi0_data_n    ;
    logic           mipi0_rstn      ;
    wire            mipi1_clk_p     ;
    wire            mipi1_clk_n     ;
    wire    [1:0]   mipi1_data_p    ;
    wire    [1:0]   mipi1_data_n    ;
    logic           mipi1_rstn      ;
    wire            i2c_scl         ;
    wire            i2c_sda         ;
    logic   [2:0]   i2c_sel         ;
    logic           dvi_tx_clk_p    ;
    logic           dvi_tx_clk_n    ;
    logic   [2:0]   dvi_tx_data_p   ;
    logic   [2:0]   dvi_tx_data_n   ;
//  logic   [7:0]   pmod0           ;
    logic   [7:0]   pmod1           ;
    logic   [7:0]   pmod2           ;
    logic   [3:0]   push_sw_n       ;
    logic   [5:0]   led_n           ;

    tang_mega_138k_pro_imx219_stereo
            #(
                .JFIVE_TCM_READMEM_FIlE ("../mem.hex")
            )
        u_top
            (
                .in_reset        ,
                .in_clk50        ,
                .uart_rx         ,
                .uart_tx         ,
                .mipi0_clk_p     ,
                .mipi0_clk_n     ,
                .mipi0_data_p    ,
                .mipi0_data_n    ,
                .mipi0_rstn      ,
                .mipi1_clk_p     ,
                .mipi1_clk_n     ,
                .mipi1_data_p    ,
                .mipi1_data_n    ,
                .mipi1_rstn      ,
                .i2c_scl         ,
                .i2c_sda         ,
                .i2c_sel         ,
                .dvi_tx_clk_p    ,
                .dvi_tx_clk_n    ,
                .dvi_tx_data_p   ,
                .dvi_tx_data_n   ,
//              .pmod0           ,
                .pmod1           ,
                .pmod2           ,
                .push_sw_n       ,
                .led_n           
            );

    assign in_reset = reset  ;
    assign in_clk50 = sys_clk;


//    always_comb force u_top.sys_lock = ~reset;
//    always_comb force u_top.sys_clk  = sys_clk;
//    always_comb force u_top.cam_clk  = cam_clk;
//    always_comb force u_top.dvi_lock = ~reset;
//    always_comb force u_top.dvi_clk  = dvi_clk;
    always_comb force u_top.u_Gowin_PLL.lock    = ~reset;
    always_comb force u_top.u_Gowin_PLL.clkout0 = sys_clk;
    always_comb force u_top.u_Gowin_PLL.clkout1 = cam_clk;
    always_comb force u_top.pll_dvi_vga.u_Gowin_PLL_dvi.lock     = ~reset;
    always_comb force u_top.pll_dvi_vga.u_Gowin_PLL_dvi.clkout0  = dvi_clk;

    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_rx_clk = dphy_clk;
    always_comb force u_top.u_imx219_mipi_rx_cam1.mipi_dphy_rx_clk = dphy_clk;


    logic   [1:0][7:0]  dphy_tx_datahs  ;
    logic               dphy_tx_validhs ;
    logic               dphy_tx_readyhs ;

    tb_generate_mipi_csi2_raw10
        u_tb_generate_mipi_csi2_raw10
            (
                .reset              (reset           ),
                .cam_clk            (cam_clk         ),
                .dphy_clk           (dphy_clk        ),
                .dphy_tx_datahs     (dphy_tx_datahs  ),
                .dphy_tx_validhs    (dphy_tx_validhs ),
                .dphy_tx_readyhs    (dphy_tx_readyhs )
            );

//    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_byte_d0    = dphy_tx_datahs[0];
//    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_byte_d1    = dphy_tx_datahs[1];
//    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_byte_ready = dphy_tx_readyhs;

    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_d0ln_hsrxd  = dphy_tx_datahs[0];
    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_d1ln_hsrxd  = dphy_tx_datahs[1];
    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_hsrxd_vld   = {2{dphy_tx_readyhs}};
    always_comb force u_top.u_imx219_mipi_rx_cam0.mipi_dphy_hsrx_en_msk = dphy_tx_readyhs;


    ////////////////////
    pullup (i2c_scl);
    pullup (i2c_sda);

    assign uart_rx = 1'b1;
    
    logic   [15:0]  wb_adr_o;
    logic   [31:0]  wb_dat_i;
    logic   [31:0]  wb_dat_o;
    logic   [3:0]   wb_sel_o;
    logic           wb_we_o;
    logic           wb_stb_o;
    logic           wb_ack_i;

    assign wb_adr_o = u_top.wb_mcu_adr_o;
    assign wb_dat_i = u_top.wb_mcu_dat_i;
    assign wb_dat_o = u_top.wb_mcu_dat_o;
    assign wb_sel_o = u_top.wb_mcu_sel_o;
    assign wb_we_o  = u_top.wb_mcu_we_o;
    assign wb_stb_o = u_top.wb_mcu_stb_o;
    assign wb_ack_i = u_top.wb_mcu_ack_i;

    always_ff @(posedge sys_clk) begin
        if ( !reset ) begin
            if ( wb_stb_o && wb_we_o && wb_adr_o == 16'h0040 ) begin
                $write("%c", wb_dat_o[7:0]);
            end
        end
    end

    final begin
        $write("\n");
    end



endmodule


`default_nettype wire


// end of file
