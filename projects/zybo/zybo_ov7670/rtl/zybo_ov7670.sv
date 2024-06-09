// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module zybo_ov7670
        #(
            parameter bit DEBUG      = 1'b1,
            parameter bit SIMULATION = 1'b0
        )
        (
            input   var logic           in_clk125,
            input   var logic   [3:0]   push_sw,
            input   var logic   [3:0]   dip_sw,
            output  var logic   [3:0]   led,

            inout   tri logic   [7:0]   pmod_a,
            inout   tri logic   [7:0]   pmod_b,
            inout   tri logic   [7:0]   pmod_c,
            inout   tri logic   [7:0]   pmod_d,
            inout   tri logic   [7:0]   pmod_e,

            inout       wire    [14:0]  DDR_addr,
            inout       wire    [2:0]   DDR_ba,
            inout       wire            DDR_cas_n,
            inout       wire            DDR_ck_n,
            inout       wire            DDR_ck_p,
            inout       wire            DDR_cke,
            inout       wire            DDR_cs_n,
            inout       wire    [3:0]   DDR_dm,
            inout       wire    [31:0]  DDR_dq,
            inout       wire    [3:0]   DDR_dqs_n,
            inout       wire    [3:0]   DDR_dqs_p,
            inout       wire            DDR_odt,
            inout       wire            DDR_ras_n,
            inout       wire            DDR_reset_n,
            inout       wire            DDR_we_n,
            inout       wire            FIXED_IO_ddr_vrn,
            inout       wire            FIXED_IO_ddr_vrp,
            inout       wire    [53:0]  FIXED_IO_mio,
            inout       wire            FIXED_IO_ps_clk,
            inout       wire            FIXED_IO_ps_porb,
            inout       wire            FIXED_IO_ps_srstb
        );


    // ---------------------------------
    //  PS
    // ---------------------------------

    logic           reset;
    logic           clk25;
    logic           clk125;

    logic           cam_reset;
    logic           cam_clk;
    logic           cam_clk_in;
    
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
    logic   [5:0]   axi4_mem_awid;
    logic   [31:0]  axi4_mem_awaddr;
    logic   [1:0]   axi4_mem_awburst;
    logic   [3:0]   axi4_mem_awcache;
    logic   [7:0]   axi4_mem_awlen;
    logic   [0:0]   axi4_mem_awlock;
    logic   [2:0]   axi4_mem_awprot;
    logic   [3:0]   axi4_mem_awqos;
    logic   [3:0]   axi4_mem_awregion;
    logic   [2:0]   axi4_mem_awsize;
    logic           axi4_mem_awvalid;
    logic           axi4_mem_awready;
    logic   [7:0]   axi4_mem_wstrb;
    logic   [63:0]  axi4_mem_wdata;
    logic           axi4_mem_wlast;
    logic           axi4_mem_wvalid;
    logic           axi4_mem_wready;
    logic   [5:0]   axi4_mem_bid;
    logic   [1:0]   axi4_mem_bresp;
    logic           axi4_mem_bvalid;
    logic           axi4_mem_bready;
    logic   [5:0]   axi4_mem_arid;
    logic   [31:0]  axi4_mem_araddr;
    logic   [1:0]   axi4_mem_arburst;
    logic   [3:0]   axi4_mem_arcache;
    logic   [7:0]   axi4_mem_arlen;
    logic   [0:0]   axi4_mem_arlock;
    logic   [2:0]   axi4_mem_arprot;
    logic   [3:0]   axi4_mem_arqos;
    logic   [3:0]   axi4_mem_arregion;
    logic   [2:0]   axi4_mem_arsize;
    logic           axi4_mem_arvalid;
    logic           axi4_mem_arready;
    logic   [5:0]   axi4_mem_rid;
    logic   [1:0]   axi4_mem_rresp;
    logic   [63:0]  axi4_mem_rdata;
    logic           axi4_mem_rlast;
    logic           axi4_mem_rvalid;
    logic           axi4_mem_rready;

    assign axi4l_peri_aresetn = ~reset;
    assign axi4l_peri_aclk    = clk125;
    assign axi4_mem_aresetn   = ~reset;
    assign axi4_mem_aclk      = clk125;

    design_1
        i_design_1
            (
                .in_reset               (push_sw[0]),
                .in_clk125              (in_clk125),
                
                .out_reset              (reset),
                .out_clk25              (clk25),
                .out_clk125             (clk125),

                .in_cam_clk             (cam_clk_in),
                .out_cam_clk            (cam_clk),
                .out_cam_reset          (cam_reset),

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
                
                .s_axi4_mem_awid        (axi4_mem_awid),
                .s_axi4_mem_awaddr      (axi4_mem_awaddr),
                .s_axi4_mem_awburst     (axi4_mem_awburst),
                .s_axi4_mem_awcache     (axi4_mem_awcache),
                .s_axi4_mem_awlen       (axi4_mem_awlen),
                .s_axi4_mem_awlock      (axi4_mem_awlock),
                .s_axi4_mem_awprot      (axi4_mem_awprot),
                .s_axi4_mem_awqos       (axi4_mem_awqos),
                .s_axi4_mem_awregion    (axi4_mem_awregion),
                .s_axi4_mem_awsize      (axi4_mem_awsize),
                .s_axi4_mem_awvalid     (axi4_mem_awvalid),
                .s_axi4_mem_awready     (axi4_mem_awready),
                .s_axi4_mem_wstrb       (axi4_mem_wstrb),
                .s_axi4_mem_wdata       (axi4_mem_wdata),
                .s_axi4_mem_wlast       (axi4_mem_wlast),
                .s_axi4_mem_wvalid      (axi4_mem_wvalid),
                .s_axi4_mem_wready      (axi4_mem_wready),
                .s_axi4_mem_bid         (axi4_mem_bid),
                .s_axi4_mem_bresp       (axi4_mem_bresp),
                .s_axi4_mem_bvalid      (axi4_mem_bvalid),
                .s_axi4_mem_bready      (axi4_mem_bready),
                .s_axi4_mem_araddr      (axi4_mem_araddr),
                .s_axi4_mem_arburst     (axi4_mem_arburst),
                .s_axi4_mem_arcache     (axi4_mem_arcache),
                .s_axi4_mem_arid        (axi4_mem_arid),
                .s_axi4_mem_arlen       (axi4_mem_arlen),
                .s_axi4_mem_arlock      (axi4_mem_arlock),
                .s_axi4_mem_arprot      (axi4_mem_arprot),
                .s_axi4_mem_arqos       (axi4_mem_arqos),
                .s_axi4_mem_arregion    (axi4_mem_arregion),
                .s_axi4_mem_arsize      (axi4_mem_arsize),
                .s_axi4_mem_arvalid     (axi4_mem_arvalid),
                .s_axi4_mem_arready     (axi4_mem_arready),
                .s_axi4_mem_rid         (axi4_mem_rid),
                .s_axi4_mem_rresp       (axi4_mem_rresp),
                .s_axi4_mem_rdata       (axi4_mem_rdata),
                .s_axi4_mem_rlast       (axi4_mem_rlast),
                .s_axi4_mem_rvalid      (axi4_mem_rvalid),
                .s_axi4_mem_rready      (axi4_mem_rready),

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
    localparam  WB_SEL_WIDTH = WB_DAT_WIDTH / 8;
    
    wire                            wb_peri_rst_i;
    wire                            wb_peri_clk_i;
    wire    [WB_ADR_WIDTH-1:0]      wb_peri_adr_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_o;
    wire                            wb_peri_we_i;
    wire    [WB_SEL_WIDTH-1:0]      wb_peri_sel_i;
    wire                            wb_peri_stb_i;
    wire                            wb_peri_ack_o;
    
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
     
    
    
    
    // ---------------------------------
    //  OV7670
    // ---------------------------------
    
//  pmod_a[0]  SCL
//  pmod_a[1]  SDA
//  pmod_a[2]  RE     (0:reset,  1:normal)
//  pmod_a[3]  PWDWN  (0:normal, 1:powerdown)
//  pmod_a[4]  VS
//  pmod_a[5]  HS
//  pmod_a[6]  SCLK
//  pmod_a[7]  PCLK

    logic           ov7670_scl    ;
    logic           ov7670_sda    ;
    logic           ov7670_reset_n;
    logic           ov7670_pwdwn  ;
    logic           ov7670_vs     ;
    logic           ov7670_hs     ;
    logic           ov7670_sysclk ;
    logic           ov7670_pclk_in;
    logic   [7:0]   ov7670_d      ;
    
    IOBUF   i_iobuf_pmod_a0 (.IO(pmod_a[0]), .I(ov7670_scl    ), .O(              ), .T(1'b0));
    IOBUF   i_iobuf_pmod_a1 (.IO(pmod_a[1]), .I(ov7670_sda    ), .O(              ), .T(1'b0));
    IOBUF   i_iobuf_pmod_a2 (.IO(pmod_a[2]), .I(ov7670_reset_n), .O(              ), .T(1'b0));
    IOBUF   i_iobuf_pmod_a3 (.IO(pmod_a[3]), .I(ov7670_pwdwn  ), .O(              ), .T(1'b0));
    IOBUF   i_iobuf_pmod_a4 (.IO(pmod_a[4]), .I(1'b0          ), .O(ov7670_vs     ), .T(1'b1));
    IOBUF   i_iobuf_pmod_a5 (.IO(pmod_a[5]), .I(1'b0          ), .O(ov7670_hs     ), .T(1'b1));
    IOBUF   i_iobuf_pmod_a6 (.IO(pmod_a[6]), .I(ov7670_sysclk ), .O(              ), .T(1'b0));
    IOBUF   i_iobuf_pmod_a7 (.IO(pmod_a[7]), .I(              ), .O(ov7670_pclk_in), .T(1'b1));

    IOBUF   i_iobuf_pmod_b0 (.IO(pmod_b[0]), .I(1'b0), .O(ov7670_d[0]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b1 (.IO(pmod_b[1]), .I(1'b0), .O(ov7670_d[1]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b2 (.IO(pmod_b[2]), .I(1'b0), .O(ov7670_d[2]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b3 (.IO(pmod_b[3]), .I(1'b0), .O(ov7670_d[3]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b4 (.IO(pmod_b[4]), .I(1'b0), .O(ov7670_d[4]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b5 (.IO(pmod_b[5]), .I(1'b0), .O(ov7670_d[5]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b6 (.IO(pmod_b[6]), .I(1'b0), .O(ov7670_d[6]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b7 (.IO(pmod_b[7]), .I(1'b0), .O(ov7670_d[7]), .T(1'b1));

    /*
    // clock
    logic           ov7670_pclk;
    BUFG    ibufg_pclk(.I(ov7670_pclk_in), .O(ov7670_pclk));

    // reset
    logic   ov7670_reset;
    jelly_reset
        u_reset
            (
                .clk        (ov7670_pclk    ),
                .in_reset   (reset          ),      // asyncrnous reset
                .out_reset  (ov7670_reset   )       // syncrnous reset
            );
    */

    assign cam_clk_in = ov7670_pclk_in;

    // input reg
    (* IOB = "true" *)   logic           in_ov7670_vs   ;
    (* IOB = "true" *)   logic           in_ov7670_hs   ;
    (* IOB = "true" *)   logic   [7:0]   in_ov7670_d    ;
    always_ff @(posedge cam_clk) begin
        in_ov7670_vs <= ov7670_vs;
        in_ov7670_hs <= ov7670_hs;
        in_ov7670_d  <= ov7670_d ;
    end
    
    logic   [15:0]   in_ov7670_h_count;
    logic   [15:0]   in_ov7670_v_count;
    always_ff @(posedge cam_clk) begin
        if ( in_ov7670_hs ) begin
            in_ov7670_h_count <= in_ov7670_h_count + 1'b1;
        end
        else begin
            in_ov7670_h_count <= '0;
        end
        if ( in_ov7670_hs && in_ov7670_h_count == '0 ) begin
            in_ov7670_v_count <= in_ov7670_v_count + 1'b1;
        end
        if ( in_ov7670_vs ) begin
            in_ov7670_v_count <= '0;
        end
    end

    // dbg
    (* mark_debug = "true" *)   logic           dbg_ov7670_vs     ;
    (* mark_debug = "true" *)   logic           dbg_ov7670_hs     ;
    (* mark_debug = "true" *)   logic   [7:0]   dbg_ov7670_d      ;
    (* mark_debug = "true" *)   logic   [15:0]  dbg_ov7670_h_count  ;       // 1280/2 = 640
    (* mark_debug = "true" *)   logic   [15:0]  dbg_ov7670_v_count  ;       // 480
    always_ff @(posedge cam_clk) begin
        dbg_ov7670_vs      <= in_ov7670_vs;
        dbg_ov7670_hs      <= in_ov7670_hs;
        dbg_ov7670_d       <= in_ov7670_d ;
        dbg_ov7670_h_count <= in_ov7670_h_count;
        dbg_ov7670_v_count <= in_ov7670_v_count;
    end


    (* mark_debug = "true" *)   logic           reg_ov7670_busy ;
    (* mark_debug = "true" *)   logic           reg_ov7670_fs   ;
    (* mark_debug = "true" *)   logic           reg_ov7670_last ;
    (* mark_debug = "true" *)   logic   [15:0]  reg_ov7670_d    ;
    (* mark_debug = "true" *)   logic           reg_ov7670_valid;
    always_ff @(posedge cam_clk) begin
        if ( cam_reset ) begin
            reg_ov7670_busy   <= 1'b0;
            reg_ov7670_fs     <= 1'bx;
            reg_ov7670_last   <= 1'bx;
            reg_ov7670_d      <= 'x;
        end
        else begin
            if ( in_ov7670_vs ) begin
                reg_ov7670_busy   <= 1'b1;
                reg_ov7670_fs     <= 1'b1;
                reg_ov7670_last   <= 1'b0;
            end
            else begin
                if ( in_ov7670_hs ) begin
                    if ( in_ov7670_h_count[0] == 1'b0 ) begin
                        reg_ov7670_d[15:8] <= in_ov7670_d;
                    end
                    else begin
                        reg_ov7670_last   <= in_ov7670_h_count == 16'd1279;
                        reg_ov7670_d[7:0] <= in_ov7670_d;
                    end
                end

                reg_ov7670_valid <= reg_ov7670_busy && in_ov7670_hs && (in_ov7670_h_count[0] == 1'b1);
                if ( reg_ov7670_valid ) begin
                    reg_ov7670_fs <= 1'b0;
                end
            end
        end
    end
    

    (* mark_debug = "true" *)   logic   [0:0]   axi4s_ov7670_tuser;
    (* mark_debug = "true" *)   logic           axi4s_ov7670_tlast;
    (* mark_debug = "true" *)   logic   [15:0]  axi4s_ov7670_tdata;
    (* mark_debug = "true" *)   logic           axi4s_ov7670_tvalid;
    (* mark_debug = "true" *)   logic           axi4s_ov7670_tready;
    always_ff @(posedge cam_clk) begin
        axi4s_ov7670_tuser  <= reg_ov7670_fs;
        axi4s_ov7670_tlast  <= reg_ov7670_last;
        axi4s_ov7670_tdata  <= reg_ov7670_d;
        axi4s_ov7670_tvalid <= reg_ov7670_valid;
    end



    // ---------------------------------
    //  DMA write
    // ---------------------------------

    // DMA write
    wire    [WB_DAT_WIDTH-1:0]  wb_vdmaw_dat_o;
    wire                        wb_vdmaw_stb_i;
    wire                        wb_vdmaw_ack_o;
    
    jelly2_dma_video_write
            #(
                .WB_ASYNC               (1),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .AXI4S_ASYNC            (1),
                .AXI4S_DATA_WIDTH       (16),
                .AXI4S_USER_WIDTH       (1),
                
                .AXI4_ID_WIDTH          (6),
                .AXI4_ADDR_WIDTH        (32),
                .AXI4_DATA_SIZE         (3),
                .AXI4_LEN_WIDTH         (8),
                .AXI4_QOS_WIDTH         (4),
                
                .INDEX_WIDTH            (1),
                .SIZE_OFFSET            (1'b1),
                .H_SIZE_WIDTH           (14),
                .V_SIZE_WIDTH           (14),
                .F_SIZE_WIDTH           (8),
                .LINE_STEP_WIDTH        (32),
                .FRAME_STEP_WIDTH       (32),
                
                .INIT_CTL_CONTROL       (4'b0000),
                .INIT_IRQ_ENABLE        (1'b0),
                .INIT_PARAM_ADDR        (0),
                .INIT_PARAM_AWLEN_MAX   (8'd255),
                .INIT_PARAM_H_SIZE      (14'(640-1)),
                .INIT_PARAM_V_SIZE      (14'(480-1)),
                .INIT_PARAM_LINE_STEP   (32'(640*2)),
                .INIT_PARAM_F_SIZE      (8'd0),
                .INIT_PARAM_FRAME_STEP  (32'(640*2)),
                .INIT_SKIP_EN           (1'b1),
                .INIT_DETECT_FIRST      (3'b010),
                .INIT_DETECT_LAST       (3'b001),
                .INIT_PADDING_EN        (1'b1),
                .INIT_PADDING_DATA      (32'd0),
                
                .BYPASS_GATE            (0),
                .BYPASS_ALIGN           (0),
                .DETECTOR_ENABLE        (1),
                .ALLOW_UNALIGNED        (1), // (0),
                .CAPACITY_WIDTH         (32),
                
                .WFIFO_PTR_WIDTH        (9),
                .WFIFO_RAM_TYPE         ("block")
            )
        i_dma_video_write
            (
                .endian                 (1'b0),
                
                .s_wb_rst_i             (wb_peri_rst_i),
                .s_wb_clk_i             (wb_peri_clk_i),
                .s_wb_adr_i             (wb_peri_adr_i[7:0]),
                .s_wb_dat_i             (wb_peri_dat_i),
                .s_wb_dat_o             (wb_vdmaw_dat_o),
                .s_wb_we_i              (wb_peri_we_i),
                .s_wb_sel_i             (wb_peri_sel_i),
                .s_wb_stb_i             (wb_vdmaw_stb_i),
                .s_wb_ack_o             (wb_vdmaw_ack_o),
                .out_irq                (),
                
                .buffer_request         (),
                .buffer_release         (),
                .buffer_addr            ('0),
                
                .s_axi4s_aresetn        (~cam_reset),
                .s_axi4s_aclk           (cam_clk),
                .s_axi4s_tuser          (axi4s_ov7670_tuser),
                .s_axi4s_tlast          (axi4s_ov7670_tlast),
                .s_axi4s_tdata          (axi4s_ov7670_tdata),
                .s_axi4s_tvalid         (axi4s_ov7670_tvalid),
                .s_axi4s_tready         (axi4s_ov7670_tready),
                
                .m_aresetn              (axi4_mem_aresetn),
                .m_aclk                 (axi4_mem_aclk),
                .m_axi4_awid            (axi4_mem_awid),
                .m_axi4_awaddr          (axi4_mem_awaddr),
                .m_axi4_awburst         (axi4_mem_awburst),
                .m_axi4_awcache         (axi4_mem_awcache),
                .m_axi4_awlen           (axi4_mem_awlen),
                .m_axi4_awlock          (axi4_mem_awlock),
                .m_axi4_awprot          (axi4_mem_awprot),
                .m_axi4_awqos           (axi4_mem_awqos),
                .m_axi4_awregion        (),
                .m_axi4_awsize          (axi4_mem_awsize),
                .m_axi4_awvalid         (axi4_mem_awvalid),
                .m_axi4_awready         (axi4_mem_awready),
                .m_axi4_wstrb           (axi4_mem_wstrb),
                .m_axi4_wdata           (axi4_mem_wdata),
                .m_axi4_wlast           (axi4_mem_wlast),
                .m_axi4_wvalid          (axi4_mem_wvalid),
                .m_axi4_wready          (axi4_mem_wready),
                .m_axi4_bid             (axi4_mem_bid),
                .m_axi4_bresp           (axi4_mem_bresp),
                .m_axi4_bvalid          (axi4_mem_bvalid),
                .m_axi4_bready          (axi4_mem_bready)
            );
  


    // ---------------------------------
    //  
    // ---------------------------------


//    assign pmod_a = 'z;
//    assign pmod_b = 'z;
    assign pmod_c = 'z;
    assign pmod_d = 'z;
    assign pmod_e = 'z;

//    assign ov7670_scl    ;
//    assign ov7670_sda    ;
    assign ov7670_reset_n = ~reset;
    assign ov7670_pwdwn   = reset;
//    assign ov7670_vs     ;
//    assign ov7670_hs     ;
    assign ov7670_sysclk = clk25;
//  assign ov7670_pclk   = clk25;
    
    logic sccb_rst_n;
    logic sccb_sda;
    logic sccb_scl;
    logic sccb_init_done;

    (* mark_debug = "true" *)   logic dbg_sccb_rst_n;
    (* mark_debug = "true" *)   logic dbg_sccb_sda;
    (* mark_debug = "true" *)   logic dbg_sccb_scl;
    (* mark_debug = "true" *)   logic dbg_sccb_init_done;
    always_ff @(posedge clk25) begin
        dbg_sccb_rst_n      <= sccb_rst_n      ;
        dbg_sccb_sda        <= sccb_sda        ;
        dbg_sccb_scl        <= sccb_scl        ;
        dbg_sccb_init_done  <= sccb_init_done  ;
    end

    logic           sccb_reset;
    logic   [15:0]   sccb_reset_cnt = 16'hffff;

    assign sccb_reset = reset || push_sw[1];
    always_ff @(posedge clk25 or posedge sccb_reset) begin
        if ( sccb_reset ) begin
            sccb_reset_cnt <= 16'hffff;
            sccb_rst_n     <= 1'b0;
        end
        else begin
            if ( sccb_reset_cnt > 0 ) begin
                sccb_reset_cnt <= sccb_reset_cnt - 1;
            end
            sccb_rst_n <= (sccb_reset_cnt == 0);
        end
    end

    assign sccb_rst_n = sccb_rst_n;
    assign ov7670_sda = sccb_sda;
    assign ov7670_scl = sccb_scl;

    sccb_top
        i_sccb_top
            (
                .clk_25m    (clk25          ),
                .rst_n      (sccb_rst_n     ),
                .sda        (sccb_sda       ),
                .scl        (sccb_scl       ),
                .init_done  (sccb_init_done )
            );
        
        /*
        input  wire  clk_25m;
        input  wire  rst_n;
        output wire  sda;
        output wire  scl;
        output wire  init_done;
        */


    // ----------------------------------------
    //  WISHBONE address decoder
    // ----------------------------------------
    
//    assign wb_gid_stb_i    = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4000_0);   // 0x40000000-0x40000fff
//    assign wb_fmtr_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_0);   // 0x40010000-0x40010fff
//    assign wb_prmup_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_1);   // 0x40011000-0x40011fff
//    assign wb_rgb_stb_i    = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_2);   // 0x40012000-0x40012fff
    assign wb_vdmaw_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4002_1);   // 0x40021000-0x40021fff
    
    assign wb_peri_dat_o  = wb_vdmaw_stb_i ? wb_vdmaw_dat_o :
                            32'h0000_0000;
    
    assign wb_peri_ack_o  = wb_vdmaw_stb_i ? wb_vdmaw_ack_o :
                            wb_peri_stb_i;



    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    logic   [31:0]      reg_counter_clk25;
    always_ff @(posedge clk25)  reg_counter_clk25 <= reg_counter_clk25 + 1;

    logic   [31:0]      reg_counter_pclk;
    always_ff @(posedge cam_clk)  reg_counter_pclk <= reg_counter_pclk + 1;

    assign led[0] = dip_sw[0];
    assign led[1] = dip_sw[1];
    assign led[2] = reg_counter_clk25[23]; 
    assign led[3] = reg_counter_pclk[23];

endmodule


`default_nettype wire

