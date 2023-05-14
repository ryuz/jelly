// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Kria KV260 RISC-V sample
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module kv260_jfive_micro_controller
            #(
                parameter   bit     SIMULATION     = 1'b0,
                parameter   bit     LOG_EXE_ENABLE = 1'b0,
                parameter   bit     LOG_MEM_ENABLE = 1'b0
            )
            (
                output  var logic           fan_en,
                output  var logic   [7:0]   pmod
            );
    
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    wire            reset;
    wire            clk;
        
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
                .fan_en                 (fan_en),
                
                .out_reset              (reset),
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
                .s_axi4l_aresetn        (~reset),
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
    //  Micro controller (RISC-V)
    // -----------------------------

    logic   [15:0]                  wb_mc_adr_o;
    logic   [31:0]                  wb_mc_dat_i;
    logic   [31:0]                  wb_mc_dat_o;
    logic   [3:0]                   wb_mc_sel_o;
    logic                           wb_mc_we_o;
    logic                           wb_mc_stb_o;
    logic                           wb_mc_ack_i;
    
    jelly2_jfive_micro_controller
            #(
                .S_WB_ADR_WIDTH     (24),
                .S_WB_DAT_WIDTH     (WB_DAT_WIDTH),
                .S_WB_TCM_ADR       (24'h0001_0000),

                .M_WB_DECODE_MASK   (32'hf000_0000),
                .M_WB_DECODE_ADDR   (32'h1000_0000),
                .M_WB_ADR_WIDTH     (16),

                .TCM_DECODE_MASK    (32'hff00_0000),
                .TCM_DECODE_ADDR    (32'h8000_0000),
                .TCM_SIZE           (4096),
                .TCM_RAM_TYPE       ("block"),
                .TCM_RAM_MODE       ("NO_CHANGE"),
                .TCM_READMEMH       (1'b0),
                .TCM_READMEM_FIlE   (""),

                .PC_WIDTH           (32),
                .INIT_PC_ADDR       (32'h8000_0000),
                .INIT_CTL_RESET     (1'b1),
                
                .DEVICE             ("ULTRASCALE"),
 
                .SIMULATION         (SIMULATION),
                .LOG_EXE_ENABLE     (LOG_EXE_ENABLE),
                .LOG_MEM_ENABLE     (LOG_MEM_ENABLE)
            )
        i_jfive_micro_controller
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),

                .s_wb_adr_i         (wb_peri_adr_i[23:0]),
                .s_wb_dat_o         (wb_peri_dat_o),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_we_i          (wb_peri_we_i),
                .s_wb_stb_i         (wb_peri_stb_i),
                .s_wb_ack_o         (wb_peri_ack_o),

                .m_wb_adr_o         (wb_mc_adr_o),
                .m_wb_dat_i         (wb_mc_dat_i),
                .m_wb_dat_o         (wb_mc_dat_o),
                .m_wb_sel_o         (wb_mc_sel_o),
                .m_wb_we_o          (wb_mc_we_o),
                .m_wb_stb_o         (wb_mc_stb_o),
                .m_wb_ack_i         (wb_mc_ack_i)
            );

    // -----------------------------
    //  Test PMOD
    // -----------------------------
    
    reg     [3:0]                   reg_gpio;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_gpio <= 0;
        end
        else begin
            if ( wb_mc_stb_o && wb_mc_we_o && wb_mc_sel_o[0] ) begin
                reg_gpio[wb_mc_adr_o[1:0]] <= wb_mc_dat_o[0];
            end
        end
    end

    assign wb_mc_ack_i = wb_mc_stb_o;

    reg     [7:0]                   reg_counter;
    always_ff @(posedge clk) begin
        reg_counter <= reg_counter + 1'b1;
    end
    
    assign pmod[3:0] = reg_gpio;
    assign pmod[7:4] = reg_counter[7:4];
    
endmodule



`default_nettype wire


// end of file
