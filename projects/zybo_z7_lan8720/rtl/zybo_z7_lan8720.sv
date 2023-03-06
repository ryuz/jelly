// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_lan8720
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
    logic           sys_clk200;
    logic           sys_clk250;
    
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
                .sys_reset              (1'b0),
                .sys_clock              (in_clk125),
                
                .out_reset              (sys_reset),
                .out_clk100             (sys_clk100),
                .out_clk200             (sys_clk200),
                .out_clk250             (sys_clk250),
                
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
    // LAN
    // ---------------------------------

    logic               mii0_refclk;
    logic               mii0_txen;
    logic   [1:0]       mii0_tx;
    logic   [1:0]       mii0_rx;
    logic               mii0_crs;
    logic               mii0_mdc;
    logic               mii0_mdio;

    IOBUF   i_iobuf_pmod_b0 (.IO(pmod_b[0]), .I(mii0_tx[0]), .O(),            .T(1'b0));
    IOBUF   i_iobuf_pmod_b1 (.IO(pmod_b[1]), .I(1'b0),       .O(mii0_rx[1]),  .T(1'b1));
    IOBUF   i_iobuf_pmod_b2 (.IO(pmod_b[2]), .I(1'b0),       .O(mii0_crs  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_b3 (.IO(pmod_b[3]), .I(1'b1),       .O(mii0_mdc  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_b4 (.IO(pmod_b[4]), .I(mii0_txen),  .O(),            .T(1'b0));
    IOBUF   i_iobuf_pmod_b5 (.IO(pmod_b[5]), .I(1'b0),       .O(mii0_rx[0]),  .T(1'b1));
    IOBUF   i_iobuf_pmod_b6 (.IO(pmod_b[6]), .I(1'b0),       .O(mii0_refclk), .T(1'b1));
    IOBUF   i_iobuf_pmod_b7 (.IO(pmod_b[7]), .I(1'b0),       .O(mii0_mdio ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_c0 (.IO(pmod_c[0]), .I(mii0_tx[1]), .O(),            .T(1'b0));

    logic               axi4s_rx0_tfirst;
    logic               axi4s_rx0_tlast;
    logic   [7:0]       axi4s_rx0_tdata;
    logic               axi4s_rx0_tvalid;

    logic               axi4s_tx0_tlast;
    logic   [7:0]       axi4s_tx0_tdata;
    logic               axi4s_tx0_tvalid;
    logic               axi4s_tx0_tready;

    rmii_phy
        i_rmii_phy_0
            (
                .reset              (sys_reset),
                .clk                (mii0_refclk),
                
                .rmii_txen          (mii0_txen),
                .rmii_tx            (mii0_tx),
                .rmii_rx            (mii0_rx),
                .rmii_crs           (mii0_crs),
                .rmii_mdc           (mii0_mdc),
                .rmii_mdio_i        (mii0_mdio),
                .rmii_mdio_o        (),
                .rmii_mdio_t        (),

                .m_axi4s_rx_tfirst  (axi4s_rx0_tfirst),
                .m_axi4s_rx_tlast   (axi4s_rx0_tlast),
                .m_axi4s_rx_tdata   (axi4s_rx0_tdata),
                .m_axi4s_rx_tvalid  (axi4s_rx0_tvalid),

                .s_axi4s_tx_tlast   (axi4s_tx0_tlast),
                .s_axi4s_tx_tdata   (axi4s_tx0_tdata),
                .s_axi4s_tx_tvalid  (axi4s_tx0_tvalid),
                .m_axi4s_tx_tready  (axi4s_tx0_tready)
            );

    always_ff @(posedge mii0_clk) begin
        if ( axi4s_rx0_tvalid ) begin
//          $display("%b %b %02h", axi4s_rx0_tfirst, axi4s_rx0_tlast, axi4s_rx0_tdata);
            if ( axi4s_rx0_tfirst ) $write("[mii] ");
            $write("%02h ", axi4s_rx0_tdata);
            if ( axi4s_rx0_tlast ) $display("");
        end
    end



    logic               mii0_clk;
    BUFG    i_bufg_mmi0_clk (.I(mii0_refclk), .O(mii0_clk));

    logic   [11:0]       mmi0_data = '0;
    always_ff @(posedge mii0_clk) begin
        mmi0_data <= mmi0_data + 1'b1;
    end
//    assign mii0_tx[1:0] = mmi0_data[1:0];
//    assign mii0_txen    = mmi0_data[7];

    always_comb begin
        mii0_txen    = 1'b0;// mmi0_data[11];
        mii0_tx[1:0] = mmi0_data[1:0];
        if ( mii0_txen ) begin
            if ( mmi0_data[10:0] < 32 ) begin
                mii0_tx[1:0] = 2'b01;
            end 
            if ( mmi0_data[10:0] == 28 ) begin
                mii0_tx[1:0] = 2'b11;
            end
        end
        else begin
            mii0_tx[1:0] = '0;
        end
    end



//  (* mark_debug = "true" *)   logic               dbg_mii0_clk;
    (* mark_debug = "true" *)   logic               dbg_mii0_txen;
    (* mark_debug = "true" *)   logic   [1:0]       dbg_mii0_tx;
    (* mark_debug = "true" *)   logic   [1:0]       dbg_mii0_rx;
    (* mark_debug = "true" *)   logic               dbg_mii0_crs;
    (* mark_debug = "true" *)   logic               dbg_mii0_mdc;
    (* mark_debug = "true" *)   logic               dbg_mii0_mdio;
    always_ff @(posedge mii0_clk) begin
//      dbg_mii0_clk    <= mii0_clk;
        dbg_mii0_txen   <= mii0_txen;
        dbg_mii0_tx     <= mii0_tx  ;
        dbg_mii0_rx     <= mii0_rx  ;
        dbg_mii0_crs    <= mii0_crs ;
        dbg_mii0_mdc    <= mii0_mdc ;
        dbg_mii0_mdio   <= mii0_mdio; 
    end

    logic               mii1_refclk;
    logic               mii1_txen;
    logic   [1:0]       mii1_tx;
    logic   [1:0]       mii1_rx;
    logic               mii1_crs;
    logic               mii1_mdc;
    logic               mii1_mdio;
    IOBUF   i_iobuf_pmod_d0 (.IO(pmod_d[0]), .I(mii1_tx[0]), .O(),            .T(1'b0));
    IOBUF   i_iobuf_pmod_d1 (.IO(pmod_d[1]), .I(1'b0),       .O(mii1_rx[1]),  .T(1'b1));
    IOBUF   i_iobuf_pmod_d2 (.IO(pmod_d[2]), .I(1'b0),       .O(mii1_crs  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_d3 (.IO(pmod_d[3]), .I(1'b1),       .O(mii1_mdc  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_d4 (.IO(pmod_d[4]), .I(mii1_txen),  .O(),            .T(1'b0));
    IOBUF   i_iobuf_pmod_d5 (.IO(pmod_d[5]), .I(1'b0),       .O(mii1_rx[0]),  .T(1'b1));
    IOBUF   i_iobuf_pmod_d6 (.IO(pmod_d[6]), .I(1'b0),       .O(mii1_refclk), .T(1'b1));
    IOBUF   i_iobuf_pmod_d7 (.IO(pmod_d[7]), .I(1'b0),       .O(mii1_mdio ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_e0 (.IO(pmod_e[0]), .I(mii1_tx[1]), .O(),            .T(1'b0));

    logic               mii1_clk;
    BUFG    i_bufg_mmi1_clk (.I(mii1_refclk), .O(mii1_clk));

    logic   [10:0]       mmi1_data = '0;
    always_ff @(posedge mii1_clk) begin
        mmi1_data <= mmi1_data + 1'b1;
    end

    always_comb begin
        mii1_txen    = 1'b0;// mmi1_data[10];
        mii1_tx[1:0] = mmi1_data[1:0];
        if ( mii1_txen ) begin
            if ( mmi1_data[9:0] < 32 ) begin
                mii1_tx[1:0] = 2'b01;
            end 
            if ( mmi1_data[9:0] == 28 ) begin
                mii1_tx[1:0] = 2'b11;
            end
        end
        else begin
            mii1_tx[1:0] = '0;
        end
    end


    /*
    assign dbg_mii1_txen = 1'b0;

    assign mii1_tx[0] = pmod_d[0];
    assign mii1_rx[1] = pmod_d[1];
    assign mii1_crs   = pmod_d[2];
    assign mii1_mdc   = pmod_d[3];
    assign mii1_txen  = pmod_d[4];
    assign mii1_rx[0] = pmod_d[5];
    assign mii1_clk   = pmod_d[6];
    assign mii1_mdio  = pmod_d[7];
    assign mii1_tx[1] = pmod_e[0];
    */

//    (* mark_debug = "true" *)   logic               dbg_mii1_clk;
    (* mark_debug = "true" *)   logic               dbg_mii1_txen;
    (* mark_debug = "true" *)   logic   [1:0]       dbg_mii1_tx;
    (* mark_debug = "true" *)   logic   [1:0]       dbg_mii1_rx;
    (* mark_debug = "true" *)   logic               dbg_mii1_crs;
    (* mark_debug = "true" *)   logic               dbg_mii1_mdc;
    (* mark_debug = "true" *)   logic               dbg_mii1_mdio;
    always_ff @(posedge mii1_clk) begin
//        dbg_mii1_clk    <= mii1_clk;
        dbg_mii1_txen   <= mii1_txen;
        dbg_mii1_tx     <= mii1_tx  ;
        dbg_mii1_rx     <= mii1_rx  ;
        dbg_mii1_crs    <= mii1_crs ;
        dbg_mii1_mdc    <= mii1_mdc ;
        dbg_mii1_mdio   <= mii1_mdio; 
    end



    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    logic   [31:0]      reg_counter_clk200;
    always_ff @(posedge sys_clk200)         reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    logic   [31:0]      reg_counter_clk100;
    always_ff @(posedge sys_clk100)         reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    logic   [31:0]      reg_counter_mii0_clk;
    always_ff @(posedge mii0_clk)           reg_counter_mii0_clk <= reg_counter_mii0_clk + 1;
    
    logic   [31:0]      reg_counter_mii1_clk;
    always_ff @(posedge mii1_clk)           reg_counter_mii1_clk <= reg_counter_mii1_clk + 1;

    logic   [31:0]      reg_counter_peri_aclk;
    always_ff @(posedge axi4l_peri_aclk)    reg_counter_peri_aclk <= reg_counter_peri_aclk + 1;

    logic   [31:0]      reg_counter_mem_aclk;
    always_ff @(posedge axi4_mem_aclk)      reg_counter_mem_aclk <= reg_counter_mem_aclk + 1;

    
    assign led[0] = reg_counter_clk200[24];
    assign led[1] = reg_counter_clk100[24];
    assign led[2] = reg_counter_mii0_clk[23]; 
    assign led[3] = reg_counter_mii1_clk[23];
    

endmodule


`default_nettype wire

