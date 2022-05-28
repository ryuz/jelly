// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//  IMX219 capture sample
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module kv260_stepper_motor
        (
            output  wire    [7:0]   pmod
        );
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    localparam  AXI4L_ADDR_WIDTH = 40;
    localparam  AXI4L_DATA_SIZE  = 3;     // 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
    localparam  AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE);
    localparam  AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH / 8;
    
    logic                           axi4l_peri_aresetn;
    logic                           axi4l_peri_aclk;
    logic   [AXI4L_ADDR_WIDTH-1:0]  axi4l_peri_awaddr;
    logic   [2:0]                   axi4l_peri_awprot;
    logic                           axi4l_peri_awvalid;
    logic                           axi4l_peri_awready;
    logic   [AXI4L_STRB_WIDTH-1:0]  axi4l_peri_wstrb;
    logic   [AXI4L_DATA_WIDTH-1:0]  axi4l_peri_wdata;
    logic                           axi4l_peri_wvalid;
    logic                           axi4l_peri_wready;
    logic   [1:0]                   axi4l_peri_bresp;
    logic                           axi4l_peri_bvalid;
    logic                           axi4l_peri_bready;
    logic   [AXI4L_ADDR_WIDTH-1:0]  axi4l_peri_araddr;
    logic   [2:0]                   axi4l_peri_arprot;
    logic                           axi4l_peri_arvalid;
    logic                           axi4l_peri_arready;
    logic   [AXI4L_DATA_WIDTH-1:0]  axi4l_peri_rdata;
    logic   [1:0]                   axi4l_peri_rresp;
    logic                           axi4l_peri_rvalid;
    logic                           axi4l_peri_rready;
    

    design_1
        i_design_1
            (
                .m_axi4l_peri_aresetn       (axi4l_peri_aresetn),
                .m_axi4l_peri_aclk          (axi4l_peri_aclk),
                .m_axi4l_peri_awaddr        (axi4l_peri_awaddr),
                .m_axi4l_peri_awprot        (axi4l_peri_awprot),
                .m_axi4l_peri_awvalid       (axi4l_peri_awvalid),
                .m_axi4l_peri_awready       (axi4l_peri_awready),
                .m_axi4l_peri_wstrb         (axi4l_peri_wstrb),
                .m_axi4l_peri_wdata         (axi4l_peri_wdata),
                .m_axi4l_peri_wvalid        (axi4l_peri_wvalid),
                .m_axi4l_peri_wready        (axi4l_peri_wready),
                .m_axi4l_peri_bresp         (axi4l_peri_bresp),
                .m_axi4l_peri_bvalid        (axi4l_peri_bvalid),
                .m_axi4l_peri_bready        (axi4l_peri_bready),
                .m_axi4l_peri_araddr        (axi4l_peri_araddr),
                .m_axi4l_peri_arprot        (axi4l_peri_arprot),
                .m_axi4l_peri_arvalid       (axi4l_peri_arvalid),
                .m_axi4l_peri_arready       (axi4l_peri_arready),
                .m_axi4l_peri_rdata         (axi4l_peri_rdata),
                .m_axi4l_peri_rresp         (axi4l_peri_rresp),
                .m_axi4l_peri_rvalid        (axi4l_peri_rvalid),
                .m_axi4l_peri_rready        (axi4l_peri_rready)
            );
    
    
    
    // AXI4L => WISHBONE
    localparam  WB_ADR_WIDTH = AXI4L_ADDR_WIDTH - AXI4L_DATA_SIZE;
    localparam  WB_DAT_SIZE  = AXI4L_DATA_SIZE;
    localparam  WB_DAT_WIDTH = AXI4L_DATA_WIDTH;
    localparam  WB_SEL_WIDTH = AXI4L_STRB_WIDTH;
    
    wire                           wb_peri_rst_i;
    wire                           wb_peri_clk_i;
    wire    [WB_ADR_WIDTH-1:0]     wb_peri_adr_i;
    wire    [WB_DAT_WIDTH-1:0]     wb_peri_dat_o;
    wire    [WB_DAT_WIDTH-1:0]     wb_peri_dat_i;
    wire    [WB_SEL_WIDTH-1:0]     wb_peri_sel_i;
    wire                           wb_peri_we_i;
    wire                           wb_peri_stb_i;
    wire                           wb_peri_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH           (AXI4L_ADDR_WIDTH),
                .AXI4L_DATA_SIZE            (AXI4L_DATA_SIZE)     // 0:8bit, 1:16bit, 2:32bit ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn            (axi4l_peri_aresetn),
                .s_axi4l_aclk               (axi4l_peri_aclk),
                .s_axi4l_awaddr             (axi4l_peri_awaddr),
                .s_axi4l_awprot             (axi4l_peri_awprot),
                .s_axi4l_awvalid            (axi4l_peri_awvalid),
                .s_axi4l_awready            (axi4l_peri_awready),
                .s_axi4l_wstrb              (axi4l_peri_wstrb),
                .s_axi4l_wdata              (axi4l_peri_wdata),
                .s_axi4l_wvalid             (axi4l_peri_wvalid),
                .s_axi4l_wready             (axi4l_peri_wready),
                .s_axi4l_bresp              (axi4l_peri_bresp),
                .s_axi4l_bvalid             (axi4l_peri_bvalid),
                .s_axi4l_bready             (axi4l_peri_bready),
                .s_axi4l_araddr             (axi4l_peri_araddr),
                .s_axi4l_arprot             (axi4l_peri_arprot),
                .s_axi4l_arvalid            (axi4l_peri_arvalid),
                .s_axi4l_arready            (axi4l_peri_arready),
                .s_axi4l_rdata              (axi4l_peri_rdata),
                .s_axi4l_rresp              (axi4l_peri_rresp),
                .s_axi4l_rvalid             (axi4l_peri_rvalid),
                .s_axi4l_rready             (axi4l_peri_rready),
                
                .m_wb_rst_o                 (wb_peri_rst_i),
                .m_wb_clk_o                 (wb_peri_clk_i),
                .m_wb_adr_o                 (wb_peri_adr_i),
                .m_wb_dat_i                 (wb_peri_dat_o),
                .m_wb_dat_o                 (wb_peri_dat_i),
                .m_wb_sel_o                 (wb_peri_sel_i),
                .m_wb_we_o                  (wb_peri_we_i),
                .m_wb_stb_o                 (wb_peri_stb_i),
                .m_wb_ack_i                 (wb_peri_ack_o)
            );
    
    
    // ----------------------------------------
    //  Global ID
    // ----------------------------------------
    
    wire    [WB_DAT_WIDTH-1:0]  wb_gid_dat_o;
    wire                        wb_gid_stb_i;
    wire                        wb_gid_ack_o;
    
    assign wb_gid_dat_o = WB_DAT_WIDTH'(32'h01234567);
    assign wb_gid_ack_o = wb_gid_stb_i;
    
    
    
    // -----------------------------
    //  stepper moter control
    // -----------------------------
    
    wire                            stmc_out_en;
    wire                            stmc_out_a;
    wire                            stmc_out_b;
    
    wire                            stmc_update;
    wire    signed  [47:0]          stmc_cur_x;
    wire    signed  [24:0]          stmc_cur_v;
    wire    signed  [24:0]          stmc_cur_a;
    wire    signed  [47:0]          stmc_target_x;
    wire    signed  [24:0]          stmc_target_v;
    wire    signed  [24:0]          stmc_target_a;
    
    wire    [WB_DAT_WIDTH-1:0]      wb_stmc_dat_o;
    wire                            wb_stmc_stb_i;
    wire                            wb_stmc_ack_o;
    
    stepper_motor_control
            #(
                .WB_ADR_WIDTH               (8),
                .WB_DAT_SIZE                (WB_DAT_SIZE),
                
                .Q_WIDTH                    (24),       // 小数点サイズ
                .MICROSTEP_WIDTH            (12),
                .X_WIDTH                    (48),
                .V_WIDTH                    (24),
                .A_WIDTH                    (24),
                .X_DIFF_WIDTH               (32),
                
                .INIT_CTL_ENABLE            (1'b0),
                .INIT_CTL_TARGET            (3'b0),
                .INIT_CTL_PWM               (2'b11),
                .INIT_TARGET_X              (0),
                .INIT_TARGET_V              (0),
                .INIT_TARGET_A              (0),
                .INIT_MAX_V                 (1000),
                .INIT_MAX_A                 (100),
                .INIT_MAX_A_NEAR            (120)
            )
        i_stepper_motor_control
            (
                .reset                      (wb_peri_rst_i),
                .clk                        (wb_peri_clk_i),
                
                .s_wb_adr_i                 (wb_peri_adr_i[7:0]),
                .s_wb_dat_i                 (wb_peri_dat_i),
                .s_wb_dat_o                 (wb_stmc_dat_o),
                .s_wb_we_i                  (wb_peri_we_i),
                .s_wb_sel_i                 (wb_peri_sel_i),
                .s_wb_stb_i                 (wb_stmc_stb_i),
                .s_wb_ack_o                 (wb_stmc_ack_o),
                
                .in_x_diff                  ('0),
                .in_valid                   (1'b0),
                
                .motor_en                   (stmc_out_en),
                .motor_a                    (stmc_out_a),
                .motor_b                    (stmc_out_b),
                
                .monitor_update             (stmc_update),
                .monitor_cur_x              (stmc_cur_x),
                .monitor_cur_v              (stmc_cur_v),
                .monitor_cur_a              (stmc_cur_a),
                .monitor_target_x           (stmc_target_x),
                .monitor_target_v           (stmc_target_v),
                .monitor_target_a           (stmc_target_a)
            );
    
    
    assign pmod[0]   = 1'b1;
    assign pmod[1]   = 1'b1;
    assign pmod[2]   = 1'b1;
    assign pmod[3]   = 1'b1;
    assign pmod[4]   =  stmc_out_a & stmc_out_en;
    assign pmod[5]   = ~stmc_out_a & stmc_out_en;
    assign pmod[6]   =  stmc_out_b & stmc_out_en;
    assign pmod[7]   = ~stmc_out_b & stmc_out_en;
    
    

    // ----------------------------------------
    //  WISHBONE address decoder
    // ----------------------------------------

    assign wb_gid_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h000);      // 0x80000000-0x8000ffff
    assign wb_stmc_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h041);      // 0x80410000-0x80041fff
    
    assign wb_peri_dat_o  = wb_gid_stb_i   ? wb_gid_dat_o   :
                            wb_stmc_stb_i  ? wb_stmc_dat_o  :
                            {WB_DAT_WIDTH{1'b0}};
    
    assign wb_peri_ack_o  = wb_gid_stb_i   ? wb_gid_ack_o   :
                            wb_stmc_stb_i  ? wb_stmc_ack_o  :
                            wb_peri_stb_i;
    
    
    
endmodule


`default_nettype wire

