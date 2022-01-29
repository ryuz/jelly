// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 udmabuf test
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module ultra96v2_hls_test
            (
                output  wire    [1:0]   led
            );
    
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    wire            resetn;
    wire            clk;
    
    wire    [0:0]   irq0;
    
    wire    [39:0]  axi4l_peri_awaddr;
    wire    [2:0]   axi4l_peri_awprot;
    wire            axi4l_peri_awvalid;
    wire            axi4l_peri_awready;
    wire    [63:0]  axi4l_peri_wdata;
    wire    [7:0]   axi4l_peri_wstrb;
    wire            axi4l_peri_wvalid;
    wire            axi4l_peri_wready;
    wire    [1:0]   axi4l_peri_bresp;
    wire            axi4l_peri_bvalid;
    wire            axi4l_peri_bready;
    wire    [39:0]  axi4l_peri_araddr;
    wire    [2:0]   axi4l_peri_arprot;
    wire            axi4l_peri_arvalid;
    wire            axi4l_peri_arready;
    wire    [63:0]  axi4l_peri_rdata;
    wire    [1:0]   axi4l_peri_rresp;
    wire            axi4l_peri_rvalid;
    wire            axi4l_peri_rready;
    
    design_1
        i_design_1
            (
                .out_resetn             (resetn),
                .out_clk                (clk),
                
                .m_axi4l_peri_awaddr    (axi4l_peri_awaddr),
                .m_axi4l_peri_awprot    (axi4l_peri_awprot),
                .m_axi4l_peri_awvalid   (axi4l_peri_awvalid),
                .m_axi4l_peri_awready   (axi4l_peri_awready),
                .m_axi4l_peri_wdata     (axi4l_peri_wdata),
                .m_axi4l_peri_wstrb     (axi4l_peri_wstrb),
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
                .m_axi4l_peri_rready    (axi4l_peri_rready)
            );
    
    
    
    // -----------------------------
    //  Peripheral BUS (WISHBONE)
    // -----------------------------
    
    localparam  WB_DAT_SIZE  = 3;
    localparam  WB_ADR_WIDTH = 40 - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
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
                .AXI4L_ADDR_WIDTH       (40),
                .AXI4L_DATA_SIZE        (3)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn        (resetn),
                .s_axi4l_aclk           (clk),
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
    
    
    // -----------------------------
    //  Test HLS
    // -----------------------------
    
    wire    [WB_DAT_WIDTH-1:0]      wb_hls_dat_o;
    wire                            wb_hls_stb_i;
    wire                            wb_hls_ack_o;
    
    test_hls
            #(
                .WB_ADR_WIDTH       (8),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH)
            )
        i_test_hls
            (
                .reset              (~resetn),
                .clk                (clk),
                
                .s_wb_adr_i         (wb_peri_adr_i[7:0]),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_dat_o         (wb_hls_dat_o),
                .s_wb_we_i          (wb_peri_we_i),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_stb_i         (wb_hls_stb_i),
                .s_wb_ack_o         (wb_hls_ack_o)
            );
    
    
    // -----------------------------
    //  Test LED
    // -----------------------------
    
    wire    [WB_DAT_WIDTH-1:0]      wb_led_dat_o;
    wire                            wb_led_stb_i;
    wire                            wb_led_ack_o;
    
    reg     [0:0]                   reg_led;
    always @(posedge clk) begin
        if ( ~resetn ) begin
            reg_led <= 0;
        end
        else begin
            if (wb_led_stb_i && wb_peri_we_i && wb_peri_sel_i[0]) begin
                reg_led <= wb_peri_dat_i[0:0];
            end
        end
    end
    
    assign wb_led_dat_o = WB_DAT_WIDTH'(reg_led);
    assign wb_led_ack_o = wb_led_stb_i;
    
    
    reg     [25:0]  reg_clk_count;
    always @(posedge clk) begin
        if ( ~resetn ) begin
            reg_clk_count <= 0;
        end
        else begin
            reg_clk_count <= reg_clk_count + 1;
        end
    end
    
    assign led[0] = reg_led;
    assign led[1] = reg_clk_count[25];
    
    
    
    // -----------------------------
    //  WISHBONE address decode
    // -----------------------------
    
    assign wb_hls_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[15:8] == 8'h00);
    assign wb_led_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[15:8] == 8'h10);
    
    assign wb_peri_dat_o = wb_hls_stb_i ? wb_hls_dat_o :
                           wb_led_stb_i ? wb_led_dat_o :
                           {WB_DAT_WIDTH{1'b0}};
    
    assign wb_peri_ack_o = wb_hls_stb_i ? wb_hls_ack_o :
                           wb_led_stb_i ? wb_led_ack_o :
                           wb_peri_stb_i;
    
    
endmodule



`default_nettype wire


// end of file
