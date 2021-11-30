// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 MPU-9250
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module ultra96v2_mpu9250
            (
                inout   wire            imu_sck,
                inout   wire            imu_sda,
                
                output  wire    [1:0]   led
            );
    
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    wire            aresetn;
    wire            aclk;
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
    wire    [0:0]   irq0;
    
    design_1
        i_design_1
            (
                .m_axi4l_aresetn        (aresetn),
                .m_axi4l_aclk           (aclk),
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
                .m_axi4l_peri_rready    (axi4l_peri_rready),
                
                .in_irq0                (irq0)
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
                .s_axi4l_aresetn        (aresetn),
                .s_axi4l_aclk           (aclk),
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
    //  I2C
    // -----------------------------
    
    
    wire                            i2c_scl_t;
    wire                            i2c_scl_i;
    wire                            i2c_sda_t;
    wire                            i2c_sda_i;
    
    wire    [WB_DAT_WIDTH-1:0]      wb_i2c_dat_o;
    wire                            wb_i2c_stb_i;
    wire                            wb_i2c_ack_o;
    
    jelly_i2c
            #(
                .DIVIDER_WIDTH          (16),
                .DIVIDER_INIT           (2000),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH)
            )
        i_i2c
            (
                .reset                  (wb_peri_rst_i),
                .clk                    (wb_peri_clk_i),
                
                .i2c_scl_t              (i2c_scl_t),
                .i2c_scl_i              (i2c_scl_i),
                .i2c_sda_t              (i2c_sda_t),
                .i2c_sda_i              (i2c_sda_i),
                
                .s_wb_adr_i             (wb_peri_adr_i[7:0]),
                .s_wb_dat_o             (wb_i2c_dat_o),
                .s_wb_dat_i             (wb_peri_dat_i),
                .s_wb_we_i              (wb_peri_we_i ),
                .s_wb_sel_i             (wb_peri_sel_i),
                .s_wb_stb_i             (wb_i2c_stb_i),
                .s_wb_ack_o             (wb_i2c_ack_o),
                
                .irq                    (irq0)
            );
    
    IOBUF i_iobuf_scl   (.IO(imu_sck), .I(1'b0), .O(i2c_scl_i), .T(i2c_scl_t));
    IOBUF i_iobuf_sda   (.IO(imu_sda), .I(1'b0), .O(i2c_sda_i), .T(i2c_sda_t));
    
    
    
    // -----------------------------
    //  Test LED
    // -----------------------------
    
    wire    [WB_DAT_WIDTH-1:0]      wb_led_dat_o;
    wire                            wb_led_stb_i;
    wire                            wb_led_ack_o;
    
    reg     [0:0]                   reg_led;
    always @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_led <= 0;
        end
        else begin
            if (wb_led_stb_i && wb_peri_we_i && wb_peri_sel_i[0]) begin
                reg_led <= wb_peri_dat_i[0:0];
            end
        end
    end
    
    assign wb_led_dat_o = reg_led;
    assign wb_led_ack_o = wb_led_stb_i;
    
    
    reg     [25:0]  reg_clk_count;
    always @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
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
    
    assign wb_i2c_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[15:8] == 16'h0000);
    assign wb_led_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[15:8] == 16'h0001);
    
    assign wb_peri_dat_o  = wb_i2c_stb_i ? wb_i2c_dat_o :
                            wb_led_stb_i ? wb_led_dat_o :
                            {WB_DAT_WIDTH{1'b0}};
    
    assign wb_peri_ack_o  = wb_i2c_stb_i ? wb_i2c_ack_o :
                            wb_led_stb_i ? wb_led_ack_o :
                            wb_peri_stb_i;
    
    
    
    // -----------------------------
    //  debug
    // -----------------------------
    
    (* mark_debug="true" *) reg     dbg_irq;
    (* mark_debug="true" *) reg     dbg_scl_t;
    (* mark_debug="true" *) reg     dbg_scl_i;
    (* mark_debug="true" *) reg     dbg_sda_t;
    (* mark_debug="true" *) reg     dbg_sda_i;
    
    always @(posedge wb_peri_clk_i) begin
        dbg_irq   <= irq0;
        dbg_scl_t <= i2c_scl_t;
        dbg_scl_i <= i2c_scl_i;
        dbg_sda_t <= i2c_sda_t;
        dbg_sda_i <= i2c_sda_i;
    end
    
    
    
endmodule



`default_nettype wire


// end of file
