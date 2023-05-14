// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_necolink_lan8720
        #(
            parameter bit DEBUG      = 1'b1,
            parameter bit SIMULATION = 1'b0
        )
        (
            input   wire            in_clk125,
            
            input   wire    [3:0]   push_sw,
            input   wire    [3:0]   dip_sw,
            output  wire    [3:0]   led,

            inout   wire    [7:0]   pmod_a,
            inout   wire    [7:0]   pmod_b,
            inout   wire    [7:0]   pmod_c,
            inout   wire    [7:0]   pmod_d,
            inout   wire    [7:0]   pmod_e,
            
            inout   wire    [14:0]  DDR_addr,
            inout   wire    [2:0]   DDR_ba,
            inout   wire            DDR_cas_n,
            inout   wire            DDR_ck_n,
            inout   wire            DDR_ck_p,
            inout   wire            DDR_cke,
            inout   wire            DDR_cs_n,
            inout   wire    [3:0]   DDR_dm,
            inout   wire    [31:0]  DDR_dq,
            inout   wire    [3:0]   DDR_dqs_n,
            inout   wire    [3:0]   DDR_dqs_p,
            inout   wire            DDR_odt,
            inout   wire            DDR_ras_n,
            inout   wire            DDR_reset_n,
            inout   wire            DDR_we_n,
            inout   wire            FIXED_IO_ddr_vrn,
            inout   wire            FIXED_IO_ddr_vrp,
            inout   wire    [53:0]  FIXED_IO_mio,
            inout   wire            FIXED_IO_ps_clk,
            inout   wire            FIXED_IO_ps_porb,
            inout   wire            FIXED_IO_ps_srstb
        );
    
    
    logic           sys_reset;
    logic           sys_clk100;
    logic           sys_clk125;
    logic           sys_clk200;
    logic           sys_clk250;

    logic           core_reset;
    logic           core_clk;

    logic           axi4l_peri_aresetn;
    logic           axi4l_peri_aclk;
    logic   [31:0]  axi4l_peri_awaddr;
    logic   [2:0]   axi4l_peri_awprot;
    logic           axi4l_peri_awvalid;
    logic           axi4l_peri_awready;
    logic   [3:0]   axi4l_peri_wstrb;
    logic   [31:0]  axi4l_peri_wdata;
    logic           axi4l_peri_wvalid;
    logic           axi4l_peri_wready;
    logic   [1:0]   axi4l_peri_bresp;
    logic           axi4l_peri_bvalid;
    logic           axi4l_peri_bready;
    logic   [31:0]  axi4l_peri_araddr;
    logic   [2:0]   axi4l_peri_arprot;
    logic           axi4l_peri_arvalid;
    logic           axi4l_peri_arready;
    logic   [31:0]  axi4l_peri_rdata;
    logic   [1:0]   axi4l_peri_rresp;
    logic           axi4l_peri_rvalid;
    logic           axi4l_peri_rready;
    

    logic           axi4_mem_aresetn;
    logic           axi4_mem_aclk;
    
    logic   [5:0]   axi4_mem0_awid;
    logic   [31:0]  axi4_mem0_awaddr;
    logic   [1:0]   axi4_mem0_awburst;
    logic   [3:0]   axi4_mem0_awcache;
    logic   [7:0]   axi4_mem0_awlen;
    logic   [0:0]   axi4_mem0_awlock;
    logic   [2:0]   axi4_mem0_awprot;
    logic   [3:0]   axi4_mem0_awqos;
    logic   [3:0]   axi4_mem0_awregion;
    logic   [2:0]   axi4_mem0_awsize;
    logic           axi4_mem0_awvalid;
    logic           axi4_mem0_awready;
    logic   [7:0]   axi4_mem0_wstrb;
    logic   [63:0]  axi4_mem0_wdata;
    logic           axi4_mem0_wlast;
    logic           axi4_mem0_wvalid;
    logic           axi4_mem0_wready;
    logic   [5:0]   axi4_mem0_bid;
    logic   [1:0]   axi4_mem0_bresp;
    logic           axi4_mem0_bvalid;
    logic           axi4_mem0_bready;
    logic   [5:0]   axi4_mem0_arid;
    logic   [31:0]  axi4_mem0_araddr;
    logic   [1:0]   axi4_mem0_arburst;
    logic   [3:0]   axi4_mem0_arcache;
    logic   [7:0]   axi4_mem0_arlen;
    logic   [0:0]   axi4_mem0_arlock;
    logic   [2:0]   axi4_mem0_arprot;
    logic   [3:0]   axi4_mem0_arqos;
    logic   [3:0]   axi4_mem0_arregion;
    logic   [2:0]   axi4_mem0_arsize;
    logic           axi4_mem0_arvalid;
    logic           axi4_mem0_arready;
    logic   [5:0]   axi4_mem0_rid;
    logic   [1:0]   axi4_mem0_rresp;
    logic   [63:0]  axi4_mem0_rdata;
    logic           axi4_mem0_rlast;
    logic           axi4_mem0_rvalid;
    logic           axi4_mem0_rready;
    
    design_1
        i_design_1
            (
                .in_reset               (1'b0),
                .in_clk125              (in_clk125),
                
                .out_reset              (sys_reset),
                .out_clk100             (sys_clk100),
                .out_clk125             (sys_clk125),
                .out_clk200             (sys_clk200),
                .out_clk250             (sys_clk250),

                .core_reset             (core_reset),
                .core_clk               (core_clk),

                .m_axi4l_peri_aresetn   (axi4l_peri_aresetn),
                .m_axi4l_peri_aclk      (axi4l_peri_aclk),
                .m_axi4l_peri_awaddr    (axi4l_peri_awaddr),
                .m_axi4l_peri_awprot    (axi4l_peri_awprot),
                .m_axi4l_peri_awvalid   (axi4l_peri_awvalid),
                .m_axi4l_peri_awready   (axi4l_peri_awready),
                .m_axi4l_peri_wstrb     (axi4l_peri_wstrb),
                .m_axi4l_peri_wdata     (axi4l_peri_wdata),
                .m_axi4l_peri_wvalid    (axi4l_peri_wvalid),
                .m_axi4l_peri_wready    (axi4l_peri_wready),
                .m_axi4l_peri_bresp     (axi4l_peri_bresp),
                .m_axi4l_peri_bvalid    (axi4l_peri_bvalid),
                .m_axi4l_peri_bready    (axi4l_peri_bready),
                .m_axi4l_peri_araddr    (axi4l_peri_araddr),
                .m_axi4l_peri_arprot    (axi4l_peri_arprot),
                .m_axi4l_peri_arvalid   (axi4l_peri_arvalid),
                .m_axi4l_peri_arready   (axi4l_peri_arready),
                .m_axi4l_peri_rdata     (axi4l_peri_rdata),
                .m_axi4l_peri_rresp     (axi4l_peri_rresp),
                .m_axi4l_peri_rvalid    (axi4l_peri_rvalid),
                .m_axi4l_peri_rready    (axi4l_peri_rready),
                
                
                .s_axi4_mem_aresetn     (axi4_mem_aresetn),
                .s_axi4_mem_aclk        (axi4_mem_aclk),
                
                .s_axi4_mem0_awid       (axi4_mem0_awid),
                .s_axi4_mem0_awaddr     (axi4_mem0_awaddr),
                .s_axi4_mem0_awburst    (axi4_mem0_awburst),
                .s_axi4_mem0_awcache    (axi4_mem0_awcache),
                .s_axi4_mem0_awlen      (axi4_mem0_awlen),
                .s_axi4_mem0_awlock     (axi4_mem0_awlock),
                .s_axi4_mem0_awprot     (axi4_mem0_awprot),
                .s_axi4_mem0_awqos      (axi4_mem0_awqos),
    //          .s_axi4_mem0_awregion   (axi4_mem0_awregion),
                .s_axi4_mem0_awsize     (axi4_mem0_awsize),
                .s_axi4_mem0_awvalid    (axi4_mem0_awvalid),
                .s_axi4_mem0_awready    (axi4_mem0_awready),
                .s_axi4_mem0_wstrb      (axi4_mem0_wstrb),
                .s_axi4_mem0_wdata      (axi4_mem0_wdata),
                .s_axi4_mem0_wlast      (axi4_mem0_wlast),
                .s_axi4_mem0_wvalid     (axi4_mem0_wvalid),
                .s_axi4_mem0_wready     (axi4_mem0_wready),
                .s_axi4_mem0_bid        (axi4_mem0_bid),
                .s_axi4_mem0_bresp      (axi4_mem0_bresp),
                .s_axi4_mem0_bvalid     (axi4_mem0_bvalid),
                .s_axi4_mem0_bready     (axi4_mem0_bready),
                .s_axi4_mem0_araddr     (axi4_mem0_araddr),
                .s_axi4_mem0_arburst    (axi4_mem0_arburst),
                .s_axi4_mem0_arcache    (axi4_mem0_arcache),
                .s_axi4_mem0_arid       (axi4_mem0_arid),
                .s_axi4_mem0_arlen      (axi4_mem0_arlen),
                .s_axi4_mem0_arlock     (axi4_mem0_arlock),
                .s_axi4_mem0_arprot     (axi4_mem0_arprot),
                .s_axi4_mem0_arqos      (axi4_mem0_arqos),
    //          .s_axi4_mem0_arregion   (axi4_mem0_arregion),
                .s_axi4_mem0_arsize     (axi4_mem0_arsize),
                .s_axi4_mem0_arvalid    (axi4_mem0_arvalid),
                .s_axi4_mem0_arready    (axi4_mem0_arready),
                .s_axi4_mem0_rid        (axi4_mem0_rid),
                .s_axi4_mem0_rresp      (axi4_mem0_rresp),
                .s_axi4_mem0_rdata      (axi4_mem0_rdata),
                .s_axi4_mem0_rlast      (axi4_mem0_rlast),
                .s_axi4_mem0_rvalid     (axi4_mem0_rvalid),
                .s_axi4_mem0_rready     (axi4_mem0_rready),
                
                .DDR_addr               (DDR_addr),
                .DDR_ba                 (DDR_ba),
                .DDR_cas_n              (DDR_cas_n),
                .DDR_ck_n               (DDR_ck_n),
                .DDR_ck_p               (DDR_ck_p),
                .DDR_cke                (DDR_cke),
                .DDR_cs_n               (DDR_cs_n),
                .DDR_dm                 (DDR_dm),
                .DDR_dq                 (DDR_dq),
                .DDR_dqs_n              (DDR_dqs_n),
                .DDR_dqs_p              (DDR_dqs_p),
                .DDR_odt                (DDR_odt),
                .DDR_ras_n              (DDR_ras_n),
                .DDR_reset_n            (DDR_reset_n),
                .DDR_we_n               (DDR_we_n),
                .FIXED_IO_ddr_vrn       (FIXED_IO_ddr_vrn),
                .FIXED_IO_ddr_vrp       (FIXED_IO_ddr_vrp),
                .FIXED_IO_mio           (FIXED_IO_mio),
                .FIXED_IO_ps_clk        (FIXED_IO_ps_clk),
                .FIXED_IO_ps_porb       (FIXED_IO_ps_porb),
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb)
            );
    
    
    // -----------------------------
    //  Peripheral BUS (WISHBONE)
    // -----------------------------
    
    localparam  WB_DAT_SIZE  = 2;
    localparam  WB_ADR_WIDTH = 32 - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    logic                           wb_peri_rst_i;
    logic                           wb_peri_clk_i;
    logic   [WB_ADR_WIDTH-1:0]      wb_peri_adr_i;
    logic   [WB_DAT_WIDTH-1:0]      wb_peri_dat_i;
    logic   [WB_DAT_WIDTH-1:0]      wb_peri_dat_o;
    logic                           wb_peri_we_i;
    logic   [WB_SEL_WIDTH-1:0]      wb_peri_sel_i;
    logic                           wb_peri_stb_i;
    logic                           wb_peri_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH       (32),
                .AXI4L_DATA_SIZE        (2)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn        (axi4l_peri_aresetn),
                .s_axi4l_aclk           (axi4l_peri_aclk),
                .s_axi4l_awaddr         (axi4l_peri_awaddr),
                .s_axi4l_awprot         (axi4l_peri_awprot),
                .s_axi4l_awvalid        (axi4l_peri_awvalid),
                .s_axi4l_awready        (axi4l_peri_awready),
                .s_axi4l_wstrb          (axi4l_peri_wstrb),
                .s_axi4l_wdata          (axi4l_peri_wdata),
                .s_axi4l_wvalid         (axi4l_peri_wvalid),
                .s_axi4l_wready         (axi4l_peri_wready),
                .s_axi4l_bresp          (axi4l_peri_bresp),
                .s_axi4l_bvalid         (axi4l_peri_bvalid),
                .s_axi4l_bready         (axi4l_peri_bready),
                .s_axi4l_araddr         (axi4l_peri_araddr),
                .s_axi4l_arprot         (axi4l_peri_arprot),
                .s_axi4l_arvalid        (axi4l_peri_arvalid),
                .s_axi4l_arready        (axi4l_peri_arready),
                .s_axi4l_rdata          (axi4l_peri_rdata),
                .s_axi4l_rresp          (axi4l_peri_rresp),
                .s_axi4l_rvalid         (axi4l_peri_rvalid),
                .s_axi4l_rready         (axi4l_peri_rready),
                
                .m_wb_rst_o             (wb_peri_rst_i),
                .m_wb_clk_o             (wb_peri_clk_i),
                .m_wb_adr_o             (wb_peri_adr_i),
                .m_wb_dat_o             (wb_peri_dat_i),
                .m_wb_dat_i             (wb_peri_dat_o),
                .m_wb_we_o              (wb_peri_we_i),
                .m_wb_sel_o             (wb_peri_sel_i),
                .m_wb_stb_o             (wb_peri_stb_i),
                .m_wb_ack_i             (wb_peri_ack_o)
            );
    
    
    
    // ----------------------------------------
    //  Global ID
    // ----------------------------------------
    
    logic   [WB_DAT_WIDTH-1:0]  wb_gid_dat_o;
    logic                       wb_gid_stb_i;
    logic                       wb_gid_ack_o;
    
    assign wb_gid_dat_o = 32'h01234567;
    assign wb_gid_ack_o = wb_gid_stb_i;
    
    
    
    // read
    assign axi4_mem0_arid     = 0;
    assign axi4_mem0_araddr   = 0;
    assign axi4_mem0_arburst  = 0;
    assign axi4_mem0_arcache  = 0;
    assign axi4_mem0_arlen    = 0;
    assign axi4_mem0_arlock   = 0;
    assign axi4_mem0_arprot   = 0;
    assign axi4_mem0_arqos    = 0;
    assign axi4_mem0_arregion = 0;
    assign axi4_mem0_arsize   = 0;
    assign axi4_mem0_arvalid  = 0;
    assign axi4_mem0_rready   = 0;
    
    
    
    // ----------------------------------------
    //  WISHBONE address decoder
    // ----------------------------------------
    
    assign wb_gid_stb_i    = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4000_0);   // 0x40000000-0x40000fff
    
    assign wb_peri_dat_o  = wb_gid_stb_i   ? wb_gid_dat_o   :
                            '0;
    
    assign wb_peri_ack_o  = wb_gid_stb_i   ? wb_gid_ack_o   :
                            wb_peri_stb_i;
    
    
    

    // ---------------------------------
    // 100BASE-TX Ether (RMII)
    // ---------------------------------

    logic   [3:0]       rmii_refclk;
    logic   [3:0]       rmii_txen;
    logic   [3:0][1:0]  rmii_tx;
    logic   [3:0][1:0]  rmii_rx;
    logic   [3:0]       rmii_crs;
    logic   [3:0]       rmii_mdc;
    logic   [3:0]       rmii_mdio_t;
    logic   [3:0]       rmii_mdio_i;
    logic   [3:0]       rmii_mdio_o;

    rmii_to_pmod
        i_rmii_to_pmod
            (
                .rmii_refclk,
                .rmii_txen,
                .rmii_tx,
                .rmii_rx,
                .rmii_crs,
                .rmii_mdc,
                .rmii_mdio_t,
                .rmii_mdio_i,
                .rmii_mdio_o,

                .pmod_a,
                .pmod_b,
                .pmod_c,
                .pmod_d,
                .pmod_e
            );


    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tfirst;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tlast;
    (* mark_debug="true" *) logic   [3:0][7:0]      axi4s_eth_rx_tdata;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tvalid;
                            logic   [3:0]           axi4s_eth_tx_tfirst;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tlast;
    (* mark_debug="true" *) logic   [3:0][7:0]      axi4s_eth_tx_tdata;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tvalid;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tready;






    wire    aresetn = ~core_reset;
    wire    aclk    = core_clk;
    
    generate
    for ( genvar i = 0; i < 4; ++i ) begin : loop_rmii_phy
        rmii_phy
                #(
                    .DEBUG              ("true")
                )
            i_rmii_phy
                (
                    .aresetn            (aresetn),
                    .aclk               (aclk),

                    .m_axi4s_rx_tfirst  (axi4s_eth_rx_tfirst[i]),
                    .m_axi4s_rx_tlast   (axi4s_eth_rx_tlast [i]),
                    .m_axi4s_rx_tdata   (axi4s_eth_rx_tdata [i]),
                    .m_axi4s_rx_tvalid  (axi4s_eth_rx_tvalid[i]),

                    .s_axi4s_tx_tlast   (axi4s_eth_tx_tlast [i]),
                    .s_axi4s_tx_tdata   (axi4s_eth_tx_tdata [i]),
                    .s_axi4s_tx_tvalid  (axi4s_eth_tx_tvalid[i]),
                    .s_axi4s_tx_tready  (axi4s_eth_tx_tready[i]),
                    
                    .rmii_refclk        (rmii_refclk[i]), 
                    .rmii_txen          (rmii_txen  [i]),
                    .rmii_tx            (rmii_tx    [i]),
                    .rmii_rx            (rmii_rx    [i]),
                    .rmii_crs           (rmii_crs   [i]),
                    .rmii_mdc           (rmii_mdc   [i]),
                    .rmii_mdio_t        (rmii_mdio_t[i]),
                    .rmii_mdio_o        (rmii_mdio_o[i]),
                    .rmii_mdio_i        (rmii_mdio_i[i])
                );
    end
    endgenerate

    // core clock
//  localparam  int unsigned    CLK_NUMERATOR   = 4;    //  4ns (250MHz)
    localparam  int unsigned    CLK_NUMERATOR   = 5;    //  5ns (200MHz)
//  localparam  int unsigned    CLK_NUMERATOR   = 8;    //  8ns (125MHz)
    localparam  int unsigned    CLK_DENOMINATOR = 1;

    localparam  int unsigned    MAX_NODES               = 4;
    localparam  int unsigned    MAX_SLAVES              = MAX_NODES - 1;

    localparam  int unsigned    TIMER_WIDTH             = 64;
    localparam  int unsigned    SYNCTIM_OFFSET_LPF_GAIN = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_CYCLE  = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_PERIOD = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_PHASE  = 8;

    localparam  int unsigned    GPIO_GLOBAL_BYTES       = 5                         ;
    localparam  int unsigned    GPIO_LOCAL_OFFSET       = GPIO_GLOBAL_BYTES         ;
    localparam  int unsigned    GPIO_LOCAL_BYTES        = 4                         ;
    localparam  int unsigned    GPIO_FULL_BYTES         = GPIO_GLOBAL_BYTES + GPIO_LOCAL_BYTES * MAX_SLAVES;

    
    // master
    logic   [TIMER_WIDTH-1:0]                           master_current_time;

    logic                   [GPIO_GLOBAL_BYTES*8-1:0]   master_gpio_tx_global;
    logic   [MAX_SLAVES-1:0][GPIO_LOCAL_BYTES *8-1:0]   master_gpio_tx_locals;
    logic                                               master_gpio_tx_accepted;

    logic                   [GPIO_GLOBAL_BYTES*8-1:0]   master_gpio_rx_global;
    logic   [MAX_SLAVES-1:0][GPIO_LOCAL_BYTES *8-1:0]   master_gpio_rx_locals;
    logic                                               master_gpio_rx_valid;

    jelly2_necolink_master
            #(
                .MAX_NODES                  (MAX_NODES                          ),
                .TIMER_WIDTH                (TIMER_WIDTH                        ),
                .NUMERATOR                  (CLK_NUMERATOR                      ),
                .DENOMINATOR                (CLK_DENOMINATOR                    ),
                .SYNCTIM_OFFSET_LPF_GAIN    (SYNCTIM_OFFSET_LPF_GAIN            ),
                .GPIO_GLOBAL_BYTES          (GPIO_GLOBAL_BYTES                  ),
                .GPIO_LOCAL_OFFSET          (GPIO_LOCAL_OFFSET                  ),
                .GPIO_LOCAL_BYTES           (GPIO_LOCAL_BYTES                   ),
                .GPIO_FULL_BYTES            (GPIO_FULL_BYTES                    ),

                .DEBUG                      (DEBUG                              ),
                .SIMULATION                 (SIMULATION                         )
            )
        u_necolink_master
            (       
                .reset                      (~aresetn                           ),
                .clk                        (aclk                               ),
                .cke                        (1'b1                               ),

                .node_self                  (                                   ),
                .node_last                  (                                   ),
                .network_looped             (                                   ),

//              .synctim_force_renew        (dip_sw[0]),        
                .external_time              ('0                                 ),
                .current_time               (master_current_time                ),

                .param_mac_enable           (1'b0                               ),
                .param_set_mac_addr_self    (1'b0                               ),
                .param_set_mac_addr_up      (1'b0                               ),
                .param_mac_addr_self        (48'h00_00_0c_00_53_00              ),
                .param_mac_addr_down        (48'hff_ff_ff_ff_ff_ff              ),
                .param_mac_addr_up          (48'hff_ff_ff_ff_ff_ff              ),
                .param_mac_type_down        (16'h0000                           ),
                .param_mac_type_up          (16'h0000                           ),

                .gpio_tx_full_data          ({master_gpio_tx_locals, master_gpio_tx_global} ),
                .gpio_tx_full_accepted      (master_gpio_tx_accepted                        ),
                .m_gpio_res_full_data       ({master_gpio_rx_locals, master_gpio_rx_global} ),
                .m_gpio_res_valid           (master_gpio_rx_valid                           ),
                
                .s_msg_outer_tx_dst_node    (8'h03                              ),
                .s_msg_outer_tx_data        (8'h5a                              ),
                .s_msg_outer_tx_valid       (1'b1                               ),
                .s_msg_outer_tx_ready       (                                   ),
                .m_msg_outer_rx_first       (                                   ),
                .m_msg_outer_rx_last        (                                   ),
                .m_msg_outer_rx_src_node    (                                   ),
                .m_msg_outer_rx_data        (                                   ),
                .m_msg_outer_rx_valid       (                                   ),
                .s_msg_inner_tx_dst_node    ('0                                 ),
                .s_msg_inner_tx_data        ('0                                 ),
                .s_msg_inner_tx_valid       ('0                                 ),
                .s_msg_inner_tx_ready       (                                   ),
                .m_msg_inner_rx_first       (                                   ),
                .m_msg_inner_rx_last        (                                   ),
                .m_msg_inner_rx_src_node    (                                   ),
                .m_msg_inner_rx_data        (                                   ),
                .m_msg_inner_rx_valid       (                                   ),

                .s_up_rx_first              (axi4s_eth_rx_tfirst[0]             ),
                .s_up_rx_last               (axi4s_eth_rx_tlast [0]             ),
                .s_up_rx_data               (axi4s_eth_rx_tdata [0]             ),
                .s_up_rx_valid              (axi4s_eth_rx_tvalid[0]             ),
                .m_up_tx_first              (axi4s_eth_tx_tfirst[0]             ),
                .m_up_tx_last               (axi4s_eth_tx_tlast [0]             ),
                .m_up_tx_data               (axi4s_eth_tx_tdata [0]             ),
                .m_up_tx_valid              (axi4s_eth_tx_tvalid[0]             ),
                .m_up_tx_ready              (axi4s_eth_tx_tready[0]             ),

                .s_down_rx_first            (axi4s_eth_rx_tfirst[1]             ),
                .s_down_rx_last             (axi4s_eth_rx_tlast [1]             ),
                .s_down_rx_data             (axi4s_eth_rx_tdata [1]             ),
                .s_down_rx_valid            (axi4s_eth_rx_tvalid[1]             ),
                .m_down_tx_first            (axi4s_eth_tx_tfirst[1]             ),
                .m_down_tx_last             (axi4s_eth_tx_tlast [1]             ),
                .m_down_tx_data             (axi4s_eth_tx_tdata [1]             ),
                .m_down_tx_valid            (axi4s_eth_tx_tvalid[1]             ),
                .m_down_tx_ready            (axi4s_eth_tx_tready[1]             )
            );


    // パルス幅を変化させる
    logic           master_pulse_duration_dir;
    logic   [5:0]   master_pulse_duration_sub;
    logic   [15:0]  master_pulse_duration;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            master_pulse_duration_dir <= 1'b0;
            master_pulse_duration_sub <= '0;
            master_pulse_duration     <= 100;
        end
        else begin
            if ( master_gpio_tx_accepted ) begin
                if ( master_pulse_duration_dir ) begin
                    {master_pulse_duration, master_pulse_duration_sub} <= {master_pulse_duration, master_pulse_duration_sub} - 1'b1;
                end
                else begin
                    {master_pulse_duration, master_pulse_duration_sub} <= {master_pulse_duration, master_pulse_duration_sub} + 1'b1;
                end

                if ( master_pulse_duration < 100 ) begin
                    master_pulse_duration_dir <= 1'b0;
                end
                if ( master_pulse_duration > 1000 ) begin
                    master_pulse_duration_dir <= 1'b1;
                end
            end
        end
    end

    // 周期トリガ
    logic   [23:0]          master_next_time;
    logic                   master_trigger;
    timer_trigger_interval_core
            #(
                .TIME_WIDTH             (24                         )
            )
        u_timer_trigger_interval_core
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (master_current_time[23:0]  ),

                .enable                 (1'b1                       ),
                .param_interval         (24'd20000                  ),
                .param_next_time_en     (1'b0                       ),
                .param_next_time        ('0                         ),

                .out_next_time          (master_next_time           ),
                .out_trigger            (master_trigger             )
            );

    assign master_gpio_tx_global = {master_pulse_duration, master_next_time};


    logic       master_pulse;
    timer_generate_pulse_core
            #(
                .TIME_WIDTH             (24                         ),
                .DURATION_WIDTH         (16                         )
            )
        u_timer_generate_pulse_core
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (master_current_time[23:0]  ),
                .trigger                (master_trigger             ),

                .enable                 (1'b1                       ),
                .param_duration         (master_pulse_duration      ),

                .out_pulse              (master_pulse               )
            );


    // slave
    logic   [TIMER_WIDTH-1:0]           slave_current_time;

    logic   [GPIO_GLOBAL_BYTES*8-1:0]   slave_gpio_rx_global;
    logic   [GPIO_LOCAL_BYTES *8-1:0]   slave_gpio_rx_local;
    logic                               slave_gpio_rx_valid;

    jelly2_necolink_slave
            #(
                .TIMER_WIDTH                (64                         ),
                .NUMERATOR                  (CLK_NUMERATOR              ),
                .DENOMINATOR                (CLK_DENOMINATOR            ),
                .SYNCTIM_LIMIT_WIDTH        (24                         ),
                .SYNCTIM_TIMER_WIDTH        (24                         ),
                .SYNCTIM_CYCLE_WIDTH        (24                         ),
                .SYNCTIM_ERROR_WIDTH        (24                         ),
                .SYNCTIM_ERROR_Q            (8                          ),
                .SYNCTIM_ADJUST_WIDTH       (24                         ),
                .SYNCTIM_ADJUST_Q           (8                          ),
                .SYNCTIM_LPF_GAIN_CYCLE     (SYNCTIM_LPF_GAIN_CYCLE     ),
                .SYNCTIM_LPF_GAIN_PERIOD    (SYNCTIM_LPF_GAIN_PERIOD    ),
                .SYNCTIM_LPF_GAIN_PHASE     (SYNCTIM_LPF_GAIN_PHASE     ),
                .GPIO_GLOBAL_BYTES          (GPIO_GLOBAL_BYTES          ),
                .GPIO_LOCAL_OFFSET          (GPIO_LOCAL_OFFSET          ),
                .GPIO_LOCAL_BYTES           (GPIO_LOCAL_BYTES           ),
                .GPIO_FULL_BYTES            (GPIO_FULL_BYTES            ),
                .DEBUG                      (DEBUG                      ),
                .SIMULATION                 (SIMULATION                 )
            )
        u_necolink_slave
            (
                .reset                      (~aresetn                   ),
                .clk                        (aclk                       ),
                .cke                        (1'b1                       ),
                
                .timsync_adj_enable         (dip_sw[1]                  ),
                .current_time               (slave_current_time         ),

                .node_self                  (                           ),
                .node_last                  (                           ),
                .network_looped             (                           ),

                .param_mac_enable           (1'b0                       ),
                .param_set_mac_addr_self    ('0                         ),
                .param_set_mac_addr_up      ('0                         ),
                .param_set_mac_addr_down    ('0                         ),
                .param_mac_addr_self        ('0                         ),
                .param_mac_addr_down        ('0                         ),
                .param_mac_addr_up          ('0                         ),
                .param_synctim_limit_min    (-24'd100000                ), // SYNCTIM_LIMIT_WIDTH
                .param_synctim_limit_max    (+24'd100000                ), // SYNCTIM_LIMIT_WIDTH
                .param_synctim_adjust_min   (-24'd10000                 ), // SYNCTIM_ERROR_WIDTH
                .param_synctim_adjust_max   (+24'd10000                 ), // SYNCTIM_ERROR_WIDTH

                .gpio_tx_global_mask        ('0                         ),
                .gpio_tx_global_data        ('0                         ),
                .gpio_tx_local_mask         ('1                         ),
                .gpio_tx_local_data         (32'hffeeddcc               ),
                .gpio_tx_accepted           (                           ),
                .m_gpio_rx_global_data      (slave_gpio_rx_global       ),
                .m_gpio_rx_local_data       (slave_gpio_rx_local        ),
                .m_gpio_rx_valid            (slave_gpio_rx_valid        ),
                .m_gpio_res_full_data       (                           ),
                .m_gpio_res_valid           (                           ),

                .s_msg_outer_tx_dst_node    (8'h00                      ),
                .s_msg_outer_tx_data        (8'h00                      ),
                .s_msg_outer_tx_valid       (1'b0                       ),
                .s_msg_outer_tx_ready       (                           ),
                .m_msg_outer_rx_first       (                           ),
                .m_msg_outer_rx_last        (                           ),
                .m_msg_outer_rx_src_node    (                           ),
                .m_msg_outer_rx_data        (                           ),
                .m_msg_outer_rx_valid       (                           ),
                .s_msg_inner_tx_dst_node    (8'h01                      ),
                .s_msg_inner_tx_data        (8'h33                      ),
                .s_msg_inner_tx_valid       (1'b1                       ),
                .s_msg_inner_tx_ready       (                           ),
                .m_msg_inner_rx_first       (                           ),
                .m_msg_inner_rx_last        (                           ),
                .m_msg_inner_rx_src_node    (                           ),
                .m_msg_inner_rx_data        (                           ),
                .m_msg_inner_rx_valid       (                           ),

                .s_up_rx_first              (axi4s_eth_rx_tfirst[2]     ),
                .s_up_rx_last               (axi4s_eth_rx_tlast [2]     ),
                .s_up_rx_data               (axi4s_eth_rx_tdata [2]     ),
                .s_up_rx_valid              (axi4s_eth_rx_tvalid[2]     ),
                .m_up_tx_first              (axi4s_eth_tx_tfirst[2]     ),
                .m_up_tx_last               (axi4s_eth_tx_tlast [2]     ),
                .m_up_tx_data               (axi4s_eth_tx_tdata [2]     ),
                .m_up_tx_valid              (axi4s_eth_tx_tvalid[2]     ),
                .m_up_tx_ready              (axi4s_eth_tx_tready[2]     ),

                .s_down_rx_first            (axi4s_eth_rx_tfirst[3]     ),
                .s_down_rx_last             (axi4s_eth_rx_tlast [3]     ),
                .s_down_rx_data             (axi4s_eth_rx_tdata [3]     ),
                .s_down_rx_valid            (axi4s_eth_rx_tvalid[3]     ),
                .m_down_tx_first            (axi4s_eth_tx_tfirst[3]     ),
                .m_down_tx_last             (axi4s_eth_tx_tlast [3]     ),
                .m_down_tx_data             (axi4s_eth_tx_tdata [3]     ),
                .m_down_tx_valid            (axi4s_eth_tx_tvalid[3]     ),
                .m_down_tx_ready            (axi4s_eth_tx_tready[3]     )
            );

    logic   [15:0]      slave_pulse_duration;
    logic   [23:0]      slave_next_time;
    logic               slave_trigger;

    always_ff @(posedge aclk) begin
        if ( slave_gpio_rx_valid ) begin
            {slave_pulse_duration, slave_next_time} <= slave_gpio_rx_global;
        end
    end
    
    timer_trigger_oneshot_core
            #(
                .TIME_WIDTH             (24)
            )
        u_trigger_oneshot
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .enable                 (1'b1                       ),

                .current_time           (slave_current_time[23:0]   ),
                .next_time              (slave_next_time            ),

                .out_trigger            (slave_trigger              )
        );

    logic       slave_pulse;
    timer_generate_pulse_core
            #(
                .TIME_WIDTH             (24                         ),
                .DURATION_WIDTH         (16                         )
            )
        u_timer_generate_pulse_core_slave
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (slave_current_time[23:0]   ),
                .trigger                (slave_trigger              ),

                .enable                 (1'b1                       ),
                .param_duration         (slave_pulse_duration       ),

                .out_pulse              (slave_pulse                )
            );


    // ----------------------------------------
    //  Output
    // ----------------------------------------
    
    IOBUF   i_iobuf_pmod_c4 (.IO(pmod_c[4]), .I(master_pulse           ), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c5 (.IO(pmod_c[5]), .I(slave_pulse            ), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c6 (.IO(pmod_c[6]), .I(master_current_time[10]), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c7 (.IO(pmod_c[7]), .I(slave_current_time [10]), .O(), .T(1'b0));



    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    logic   [31:0]      reg_counter_clk200;
    always_ff @(posedge sys_clk200)         reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    logic   [31:0]      reg_counter_clk100;
    always_ff @(posedge sys_clk100)         reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    logic   [31:0]      reg_counter_mii0_clk;
    always_ff @(posedge rmii_refclk[0])     reg_counter_mii0_clk <= reg_counter_mii0_clk + 1;
    
    logic   [31:0]      reg_counter_mii1_clk;
    always_ff @(posedge rmii_refclk[1])     reg_counter_mii1_clk <= reg_counter_mii1_clk + 1;

    logic   [31:0]      reg_counter_peri_aclk;
    always_ff @(posedge axi4l_peri_aclk)    reg_counter_peri_aclk <= reg_counter_peri_aclk + 1;

    logic   [31:0]      reg_counter_mem_aclk;
    always_ff @(posedge axi4_mem_aclk)      reg_counter_mem_aclk <= reg_counter_mem_aclk + 1;


    assign led[0] = dip_sw[0];
    assign led[1] = dip_sw[1];

//    assign led[0] = reg_counter_clk200[24];
//    assign led[1] = reg_counter_clk100[24];
    assign led[2] = reg_counter_mii0_clk[23]; 
    assign led[3] = reg_counter_mii1_clk[23];
    

endmodule


`default_nettype wire

