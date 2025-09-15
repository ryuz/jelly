// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//  IMX219 capture sample
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------




`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_rtcl_py300
        #(
            parameter   X_NUM = 3280,
            parameter   Y_NUM = 2464
        )
        (
            input   var logic           in_clk125           ,
            
            input   var logic   [3:0]   push_sw             ,
            input   var logic   [3:0]   dip_sw              ,
            output  var logic   [3:0]   led                 ,
            output  var logic   [7:0]   pmod_a              ,
            inout   tri logic   [7:0]   pmod_b              ,
            inout   tri logic   [7:0]   pmod_c              ,
            inout   tri logic   [7:0]   pmod_d              ,
            inout   tri logic   [7:0]   pmod_e              ,
            
            input   var logic           cam_clk_hs_p        ,
            input   var logic           cam_clk_hs_n        ,
            input   var logic           cam_clk_lp_p        ,
            input   var logic           cam_clk_lp_n        ,
            input   var logic   [1:0]   cam_data_hs_p       ,
            input   var logic   [1:0]   cam_data_hs_n       ,
            input   var logic   [1:0]   cam_data_lp_p       ,
            input   var logic   [1:0]   cam_data_lp_n       ,
            input   var logic           cam_clk             ,
            output  var logic           cam_gpio            ,
            inout   tri logic           cam_scl             ,
            inout   tri logic           cam_sda             ,
            
            inout   tri logic   [14:0]  DDR_addr            ,
            inout   tri logic   [2:0]   DDR_ba              ,
            inout   tri logic           DDR_cas_n           ,
            inout   tri logic           DDR_ck_n            ,
            inout   tri logic           DDR_ck_p            ,
            inout   tri logic           DDR_cke             ,
            inout   tri logic           DDR_cs_n            ,
            inout   tri logic   [3:0]   DDR_dm              ,
            inout   tri logic   [31:0]  DDR_dq              ,
            inout   tri logic   [3:0]   DDR_dqs_n           ,
            inout   tri logic   [3:0]   DDR_dqs_p           ,
            inout   tri logic           DDR_odt             ,
            inout   tri logic           DDR_ras_n           ,
            inout   tri logic           DDR_reset_n         ,
            inout   tri logic           DDR_we_n            ,
            inout   tri logic           FIXED_IO_ddr_vrn    ,
            inout   tri logic           FIXED_IO_ddr_vrp    ,
            inout   tri logic   [53:0]  FIXED_IO_mio        ,
            inout   tri logic           FIXED_IO_ps_clk     ,
            inout   tri logic           FIXED_IO_ps_porb    ,
            inout   tri logic           FIXED_IO_ps_srstb   
        );
    
    
    wire            sys_reset   ;
    wire            sys_clk100  ;
    wire            sys_clk200  ;
    wire            sys_clk250  ;
    
    wire            axi4l_peri_aresetn  ;
    wire            axi4l_peri_aclk     ;
    wire    [31:0]  axi4l_peri_awaddr   ;
    wire    [2:0]   axi4l_peri_awprot   ;
    wire            axi4l_peri_awvalid  ;
    wire            axi4l_peri_awready  ;
    wire    [3:0]   axi4l_peri_wstrb    ;
    wire    [31:0]  axi4l_peri_wdata    ;
    wire            axi4l_peri_wvalid   ;
    wire            axi4l_peri_wready   ;
    wire    [1:0]   axi4l_peri_bresp    ;
    wire            axi4l_peri_bvalid   ;
    wire            axi4l_peri_bready   ;
    wire    [31:0]  axi4l_peri_araddr   ;
    wire    [2:0]   axi4l_peri_arprot   ;
    wire            axi4l_peri_arvalid  ;
    wire            axi4l_peri_arready  ;
    wire    [31:0]  axi4l_peri_rdata    ;
    wire    [1:0]   axi4l_peri_rresp    ;
    wire            axi4l_peri_rvalid   ;
    wire            axi4l_peri_rready   ;
    
    
    wire            axi4_mem_aresetn    ;
    wire            axi4_mem_aclk       ;
    
    wire    [5:0]   axi4_mem0_awid      ;
    wire    [31:0]  axi4_mem0_awaddr    ;
    wire    [1:0]   axi4_mem0_awburst   ;
    wire    [3:0]   axi4_mem0_awcache   ;
    wire    [7:0]   axi4_mem0_awlen     ;
    wire    [0:0]   axi4_mem0_awlock    ;
    wire    [2:0]   axi4_mem0_awprot    ;
    wire    [3:0]   axi4_mem0_awqos     ;
    wire    [3:0]   axi4_mem0_awregion  ;
    wire    [2:0]   axi4_mem0_awsize    ;
    wire            axi4_mem0_awvalid   ;
    wire            axi4_mem0_awready   ;
    wire    [7:0]   axi4_mem0_wstrb     ;
    wire    [63:0]  axi4_mem0_wdata     ;
    wire            axi4_mem0_wlast     ;
    wire            axi4_mem0_wvalid    ;
    wire            axi4_mem0_wready    ;
    wire    [5:0]   axi4_mem0_bid       ;
    wire    [1:0]   axi4_mem0_bresp     ;
    wire            axi4_mem0_bvalid    ;
    wire            axi4_mem0_bready    ;
    wire    [5:0]   axi4_mem0_arid      ;
    wire    [31:0]  axi4_mem0_araddr    ;
    wire    [1:0]   axi4_mem0_arburst   ;
    wire    [3:0]   axi4_mem0_arcache   ;
    wire    [7:0]   axi4_mem0_arlen     ;
    wire    [0:0]   axi4_mem0_arlock    ;
    wire    [2:0]   axi4_mem0_arprot    ;
    wire    [3:0]   axi4_mem0_arqos     ;
    wire    [3:0]   axi4_mem0_arregion  ;
    wire    [2:0]   axi4_mem0_arsize    ;
    wire            axi4_mem0_arvalid   ;
    wire            axi4_mem0_arready   ;
    wire    [5:0]   axi4_mem0_rid       ;
    wire    [1:0]   axi4_mem0_rresp     ;
    wire    [63:0]  axi4_mem0_rdata     ;
    wire            axi4_mem0_rlast     ;
    wire            axi4_mem0_rvalid    ;
    wire            axi4_mem0_rready    ;
    
    wire            IIC_0_0_scl_i;
    wire            IIC_0_0_scl_o;
    wire            IIC_0_0_scl_t;
    wire            IIC_0_0_sda_i;
    wire            IIC_0_0_sda_o;
    wire            IIC_0_0_sda_t;
    
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
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb),
                
                .IIC_0_0_scl_i          (IIC_0_0_scl_i),
                .IIC_0_0_scl_o          (IIC_0_0_scl_o),
                .IIC_0_0_scl_t          (IIC_0_0_scl_t),
                .IIC_0_0_sda_i          (IIC_0_0_sda_i),
                .IIC_0_0_sda_o          (IIC_0_0_sda_o),
                .IIC_0_0_sda_t          (IIC_0_0_sda_t)
            );
    
    IOBUF
        i_IOBUF_cam_scl
            (
                .IO     (cam_scl),
                .I      (IIC_0_0_scl_o),
                .O      (IIC_0_0_scl_i),
                .T      (IIC_0_0_scl_t)
            );

    IOBUF
        i_iobuf_cam_sda
            (
                .IO     (cam_sda),
                .I      (IIC_0_0_sda_o),
                .O      (IIC_0_0_sda_i),
                .T      (IIC_0_0_sda_t)
            );
    

    
    // -----------------------------
    //  Peripheral BUS (WISHBONE)
    // -----------------------------
    
    localparam  WB_DAT_SIZE  = 2;
    localparam  WB_ADR_WIDTH = 32 - WB_DAT_SIZE;
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
    //  System Control
    // ----------------------------------------
    
    logic   [WB_DAT_WIDTH-1:0]  wb_sys_dat_o;
    logic                       wb_sys_stb_i;
    logic                       wb_sys_ack_o;
        
    (* MARK_DEBUG = "true" *)   logic                       reg_sw_reset;
    (* MARK_DEBUG = "true" *)   logic                       reg_cam_enable;
                                logic   [7:0]               reg_csi_data_type;
                                logic                       reg_dphy_init_done;
    always_ff @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_sw_reset      <= 1'b0;
            reg_cam_enable    <= 1'b0;
            reg_csi_data_type <= 8'h2b;
        end
        else begin
            if ( wb_sys_stb_i && wb_peri_we_i ) begin
                case ( wb_peri_adr_i[3:0] )
                1: reg_sw_reset      <= 1'(wb_peri_dat_i);
                2: reg_cam_enable    <= 1'(wb_peri_dat_i);
                3: reg_csi_data_type <= 8'(wb_peri_dat_i);
                endcase
            end
        end
    end
    
    assign wb_sys_dat_o = wb_peri_adr_i[3:0] == 0 ? WB_DAT_WIDTH'(32'h01234567)         :
                          wb_peri_adr_i[3:0] == 1 ? WB_DAT_WIDTH'(reg_sw_reset)         :
                          wb_peri_adr_i[3:0] == 2 ? WB_DAT_WIDTH'(reg_cam_enable)       :
                          wb_peri_adr_i[3:0] == 3 ? WB_DAT_WIDTH'(reg_csi_data_type)    :
                          wb_peri_adr_i[3:0] == 4 ? WB_DAT_WIDTH'(reg_dphy_init_done)   :
                          '0;
    assign wb_sys_ack_o = wb_sys_stb_i;

    assign cam_gpio = reg_cam_enable & dip_sw[0];
    

    
    // ----------------------------------------
    //  MIPI D-PHY RX
    // ----------------------------------------
    
                            wire                rxbyteclkhs;
    (* mark_debug="true" *) wire                system_rst_out;
    (* mark_debug="true" *) wire                init_done;
    
    (* mark_debug="true" *) wire                cl_rxclkactivehs;
    (* mark_debug="true" *) wire                cl_stopstate;
    (* mark_debug="true" *) wire                cl_enable         = 1;
    (* mark_debug="true" *) wire                cl_rxulpsclknot;
    (* mark_debug="true" *) wire                cl_ulpsactivenot;
    
    (* mark_debug="true" *) wire    [7:0]       dl0_rxdatahs;
    (* mark_debug="true" *) wire                dl0_rxvalidhs;
    (* mark_debug="true" *) wire                dl0_rxactivehs;
    (* mark_debug="true" *) wire                dl0_rxsynchs;
    (* mark_debug="true" *) wire                dl0_forcerxmode   = 0;
    (* mark_debug="true" *) wire                dl0_stopstate;
    (* mark_debug="true" *) wire                dl0_enable        = 1;
    (* mark_debug="true" *) wire                dl0_ulpsactivenot;
    (* mark_debug="true" *) wire                dl0_rxclkesc;
    (* mark_debug="true" *) wire                dl0_rxlpdtesc;
    (* mark_debug="true" *) wire                dl0_rxulpsesc;
    (* mark_debug="true" *) wire    [3:0]       dl0_rxtriggeresc;
    (* mark_debug="true" *) wire    [7:0]       dl0_rxdataesc;
    (* mark_debug="true" *) wire                dl0_rxvalidesc;
    (* mark_debug="true" *) wire                dl0_errsoths;
    (* mark_debug="true" *) wire                dl0_errsotsynchs;
    (* mark_debug="true" *) wire                dl0_erresc;
    (* mark_debug="true" *) wire                dl0_errsyncesc;
    (* mark_debug="true" *) wire                dl0_errcontrol;
    
    (* mark_debug="true" *) wire    [7:0]       dl1_rxdatahs;
    (* mark_debug="true" *) wire                dl1_rxvalidhs;
    (* mark_debug="true" *) wire                dl1_rxactivehs;
    (* mark_debug="true" *) wire                dl1_rxsynchs;
    (* mark_debug="true" *) wire                dl1_forcerxmode   = 0;
    (* mark_debug="true" *) wire                dl1_stopstate;
    (* mark_debug="true" *) wire                dl1_enable        = 1;
    (* mark_debug="true" *) wire                dl1_ulpsactivenot;
    (* mark_debug="true" *) wire                dl1_rxclkesc;
    (* mark_debug="true" *) wire                dl1_rxlpdtesc;
    (* mark_debug="true" *) wire                dl1_rxulpsesc;
    (* mark_debug="true" *) wire    [3:0]       dl1_rxtriggeresc;
    (* mark_debug="true" *) wire    [7:0]       dl1_rxdataesc;
    (* mark_debug="true" *) wire                dl1_rxvalidesc;
    (* mark_debug="true" *) wire                dl1_errsoths;
    (* mark_debug="true" *) wire                dl1_errsotsynchs;
    (* mark_debug="true" *) wire                dl1_erresc;
    (* mark_debug="true" *) wire                dl1_errsyncesc;
    (* mark_debug="true" *) wire                dl1_errcontrol;
    
    /*
    (* mark_debug="true" *) logic   [7:0]       dl0_rxdatahs_exp;
    (* mark_debug="true" *) logic               dl0_check_ng;
    (* mark_debug="true" *) logic   [7:0]       dl1_rxdatahs_exp;
    (* mark_debug="true" *) logic               dl1_check_ng;
    always_ff @(posedge rxbyteclkhs) begin
        if ( dl0_rxvalidhs ) begin
            dl0_rxdatahs_exp <= dl0_rxdatahs + 1;
            dl0_check_ng <= (dl0_rxdatahs != dl0_rxdatahs_exp);
        end
    end
    always_ff @(posedge rxbyteclkhs) begin
        if ( dl1_rxvalidhs ) begin
            dl1_rxdatahs_exp <= dl1_rxdatahs - 1;
            dl1_check_ng <= (dl1_rxdatahs != dl1_rxdatahs_exp);
        end
    end
    */

    mipi_dphy_cam
        i_mipi_dphy_cam
            (
                .core_clk           (sys_clk200),
                .core_rst           (sys_reset | reg_sw_reset),
                .rxbyteclkhs        (rxbyteclkhs),
                .system_rst_out     (system_rst_out),
                .init_done          (init_done),
                
                .cl_rxclkactivehs   (cl_rxclkactivehs),
                .cl_stopstate       (cl_stopstate),
                .cl_enable          (cl_enable),
                .cl_rxulpsclknot    (cl_rxulpsclknot),
                .cl_ulpsactivenot   (cl_ulpsactivenot),
                
                .dl0_rxdatahs       (dl0_rxdatahs),
                .dl0_rxvalidhs      (dl0_rxvalidhs),
                .dl0_rxactivehs     (dl0_rxactivehs),
                .dl0_rxsynchs       (dl0_rxsynchs),
                
                .dl0_forcerxmode    (dl0_forcerxmode),
                .dl0_stopstate      (dl0_stopstate),
                .dl0_enable         (dl0_enable),
                .dl0_ulpsactivenot  (dl0_ulpsactivenot),
                
                .dl0_rxclkesc       (dl0_rxclkesc),
                .dl0_rxlpdtesc      (dl0_rxlpdtesc),
                .dl0_rxulpsesc      (dl0_rxulpsesc),
                .dl0_rxtriggeresc   (dl0_rxtriggeresc),
                .dl0_rxdataesc      (dl0_rxdataesc),
                .dl0_rxvalidesc     (dl0_rxvalidesc),
                
                .dl0_errsoths       (dl0_errsoths),
                .dl0_errsotsynchs   (dl0_errsotsynchs),
                .dl0_erresc         (dl0_erresc),
                .dl0_errsyncesc     (dl0_errsyncesc),
                .dl0_errcontrol     (dl0_errcontrol),
                
                .dl1_rxdatahs       (dl1_rxdatahs),
                .dl1_rxvalidhs      (dl1_rxvalidhs),
                .dl1_rxactivehs     (dl1_rxactivehs),
                .dl1_rxsynchs       (dl1_rxsynchs),
                
                .dl1_forcerxmode    (dl1_forcerxmode),
                .dl1_stopstate      (dl1_stopstate),
                .dl1_enable         (dl1_enable),
                .dl1_ulpsactivenot  (dl1_ulpsactivenot),
                
                .dl1_rxclkesc       (dl1_rxclkesc),
                .dl1_rxlpdtesc      (dl1_rxlpdtesc),
                .dl1_rxulpsesc      (dl1_rxulpsesc),
                .dl1_rxtriggeresc   (dl1_rxtriggeresc),
                .dl1_rxdataesc      (dl1_rxdataesc),
                .dl1_rxvalidesc     (dl1_rxvalidesc),
                
                .dl1_errsoths       (dl1_errsoths),
                .dl1_errsotsynchs   (dl1_errsotsynchs),
                .dl1_erresc         (dl1_erresc),
                .dl1_errsyncesc     (dl1_errsyncesc),
                .dl1_errcontrol     (dl1_errcontrol),
                
                .clk_hs_rxp         (cam_clk_hs_p),
                .clk_hs_rxn         (cam_clk_hs_n),
                .clk_lp_rxp         (cam_clk_lp_p),
                .clk_lp_rxn         (cam_clk_lp_n),
                .data_hs_rxp        (cam_data_hs_p),
                .data_hs_rxn        (cam_data_hs_n),
                .data_lp_rxp        (cam_data_lp_p),
                .data_lp_rxn        (cam_data_lp_n)
           );
    
    always_ff @(posedge wb_peri_clk_i) begin
        reg_dphy_init_done <= init_done;
    end

    wire        dphy_clk   = rxbyteclkhs;
    wire        dphy_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (0),
                .OUT_LOW_ACTIVE     (0),
                .INPUT_REGS         (2),
                .COUNTER_WIDTH      (5),
                .INSERT_BUFG        (0)
            )
        i_reset
            (
                .clk                (dphy_clk),
                .in_reset           (sys_reset || system_rst_out),
                .out_reset          (dphy_reset)
            );
    
    
    
    
    // ----------------------------------------
    //  CSI-2
    // ----------------------------------------
    
    
    wire            axi4s_cam_aresetn = ~sys_reset;
    wire            axi4s_cam_aclk    = sys_clk200;
    
    (* mark_debug="true" *) wire    [0:0]   axi4s_csi2_tuser;
    (* mark_debug="true" *) wire            axi4s_csi2_tlast;
    (* mark_debug="true" *) wire    [9:0]   axi4s_csi2_tdata;
    (* mark_debug="true" *) wire            axi4s_csi2_tvalid;
    (* mark_debug="true" *) wire            axi4s_csi2_tready;
    
    jelly_mipi_csi2_rx
            #(
                .LANES              (2),
                .DATA_WIDTH         (10),
                .M_FIFO_ASYNC       (1)
            )
        i_mipi_csi2_rx
            (
                .aresetn            (~sys_reset),
                .aclk               (sys_clk250),
                
                .rxreseths          (system_rst_out),
                .rxbyteclkhs        (rxbyteclkhs),
                .rxdatahs           ({dl1_rxdatahs,   dl0_rxdatahs  }),
                .rxvalidhs          ({dl1_rxvalidhs,  dl0_rxvalidhs }),
                .rxactivehs         ({dl1_rxactivehs, dl0_rxactivehs}),
                .rxsynchs           ({dl1_rxsynchs,   dl0_rxsynchs  }),
                
                .m_axi4s_aresetn    (axi4s_cam_aresetn),
                .m_axi4s_aclk       (axi4s_cam_aclk),
                .m_axi4s_tuser      (axi4s_csi2_tuser),
                .m_axi4s_tlast      (axi4s_csi2_tlast),
                .m_axi4s_tdata      (axi4s_csi2_tdata),
                .m_axi4s_tvalid     (axi4s_csi2_tvalid),
                .m_axi4s_tready     (1'b1)  // (axi4s_csi2_tready)
            );
    
    
    // normalize
    (* mark_debug="true" *) wire    [0:0]               axi4s_fmtr_tuser;
    (* mark_debug="true" *) wire                        axi4s_fmtr_tlast;
    (* mark_debug="true" *) wire    [9:0]               axi4s_fmtr_tdata;
    (* mark_debug="true" *) wire                        axi4s_fmtr_tvalid;
    (* mark_debug="true" *) wire                        axi4s_fmtr_tready;
    
    wire    [WB_DAT_WIDTH-1:0]  wb_fmtr_dat_o;
    wire                        wb_fmtr_stb_i;
    wire                        wb_fmtr_ack_o;
    
    jelly_video_format_regularizer
            #(
                .WB_ADR_WIDTH       (8),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                
                .TUSER_WIDTH        (1),
                .TDATA_WIDTH        (10),
                .X_WIDTH            (16),
                .Y_WIDTH            (16),
                .TIMER_WIDTH        (32),
                .S_SLAVE_REGS       (1),
                .S_MASTER_REGS      (1),
                .M_SLAVE_REGS       (1),
                .M_MASTER_REGS      (1),
                
                .INIT_CTL_CONTROL   (2'b00),
                .INIT_CTL_SKIP      (1),
                .INIT_PARAM_WIDTH   (X_NUM),
                .INIT_PARAM_HEIGHT  (Y_NUM),
                .INIT_PARAM_FILL    (10'd0),
                .INIT_PARAM_TIMEOUT (32'h00010000)
            )
        i_video_format_regularizer
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),
                
                .s_wb_rst_i         (wb_peri_rst_i),
                .s_wb_clk_i         (wb_peri_clk_i),
                .s_wb_adr_i         (wb_peri_adr_i[7:0]),
                .s_wb_dat_o         (wb_fmtr_dat_o),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_we_i          (wb_peri_we_i),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_stb_i         (wb_fmtr_stb_i),
                .s_wb_ack_o         (wb_fmtr_ack_o),
                
                .s_axi4s_tuser      (axi4s_csi2_tuser),
                .s_axi4s_tlast      (axi4s_csi2_tlast),
                .s_axi4s_tdata      (axi4s_csi2_tdata),
                .s_axi4s_tvalid     (axi4s_csi2_tvalid),
                .s_axi4s_tready     (axi4s_csi2_tready),
                
                .m_axi4s_tuser      (axi4s_fmtr_tuser),
                .m_axi4s_tlast      (axi4s_fmtr_tlast),
                .m_axi4s_tdata      (axi4s_fmtr_tdata),
                .m_axi4s_tvalid     (axi4s_fmtr_tvalid),
                .m_axi4s_tready     (axi4s_fmtr_tready)
            );
    
    
    
    // DMA write
    wire    [WB_DAT_WIDTH-1:0]  wb_vdmaw_dat_o;
    wire                        wb_vdmaw_stb_i;
    wire                        wb_vdmaw_ack_o;
    
    jelly_vdma_axi4s_to_axi4
            #(
                .ASYNC              (1),
                .FIFO_PTR_WIDTH     (12),
                
                .PIXEL_SIZE         (2),    // 32bit
                .AXI4_ID_WIDTH      (6),
                .AXI4_ADDR_WIDTH    (32),
                .AXI4_DATA_SIZE     (3),    // 64bit
                .AXI4S_DATA_SIZE    (2),    // 32bit
                .AXI4S_USER_WIDTH   (1),
                .INDEX_WIDTH        (8),
                .STRIDE_WIDTH       (16),
                .H_WIDTH            (14),
                .V_WIDTH            (14),
                .SIZE_WIDTH         (32),
                
                .WB_ADR_WIDTH       (8),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .INIT_CTL_CONTROL   (2'b00),
                .INIT_PARAM_ADDR    (32'h3000_0000),
                .INIT_PARAM_STRIDE  (X_NUM*2),
                .INIT_PARAM_WIDTH   (X_NUM),
                .INIT_PARAM_HEIGHT  (Y_NUM),
                .INIT_PARAM_SIZE    (X_NUM*Y_NUM),
                .INIT_PARAM_AWLEN   (7)
            )
        i_vdma_axi4s_to_axi4
            (
                .m_axi4_aresetn     (axi4_mem_aresetn),
                .m_axi4_aclk        (axi4_mem_aclk),
                .m_axi4_awid        (axi4_mem0_awid),
                .m_axi4_awaddr      (axi4_mem0_awaddr),
                .m_axi4_awburst     (axi4_mem0_awburst),
                .m_axi4_awcache     (axi4_mem0_awcache),
                .m_axi4_awlen       (axi4_mem0_awlen),
                .m_axi4_awlock      (axi4_mem0_awlock),
                .m_axi4_awprot      (axi4_mem0_awprot),
                .m_axi4_awqos       (axi4_mem0_awqos),
                .m_axi4_awregion    (),
                .m_axi4_awsize      (axi4_mem0_awsize),
                .m_axi4_awvalid     (axi4_mem0_awvalid),
                .m_axi4_awready     (axi4_mem0_awready),
                .m_axi4_wstrb       (axi4_mem0_wstrb),
                .m_axi4_wdata       (axi4_mem0_wdata),
                .m_axi4_wlast       (axi4_mem0_wlast),
                .m_axi4_wvalid      (axi4_mem0_wvalid),
                .m_axi4_wready      (axi4_mem0_wready),
                .m_axi4_bid         (axi4_mem0_bid),
                .m_axi4_bresp       (axi4_mem0_bresp),
                .m_axi4_bvalid      (axi4_mem0_bvalid),
                .m_axi4_bready      (axi4_mem0_bready),
                
                .s_axi4s_aresetn    (axi4s_cam_aresetn),
                .s_axi4s_aclk       (axi4s_cam_aclk),
                .s_axi4s_tuser      (axi4s_fmtr_tuser),
                .s_axi4s_tlast      (axi4s_fmtr_tlast),
                .s_axi4s_tdata      (axi4s_fmtr_tdata),
                .s_axi4s_tvalid     (axi4s_fmtr_tvalid),
                .s_axi4s_tready     (axi4s_fmtr_tready),
                
                .s_wb_rst_i         (wb_peri_rst_i),
                .s_wb_clk_i         (wb_peri_clk_i),
                .s_wb_adr_i         (wb_peri_adr_i[7:0]),
                .s_wb_dat_o         (wb_vdmaw_dat_o),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_we_i          (wb_peri_we_i),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_stb_i         (wb_vdmaw_stb_i),
                .s_wb_ack_o         (wb_vdmaw_ack_o)
            );
    
    
    // read 縺ｯ譛ｪ菴ｿ逕ｨ
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
    
    assign wb_sys_stb_i    = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4000_0);   // 0x40000000-0x40000fff
    assign wb_fmtr_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_0);   // 0x40010000-0x40010fff
//  assign wb_prmup_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_1);   // 0x40011000-0x40011fff
//  assign wb_rgb_stb_i    = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4001_2);   // 0x40012000-0x40012fff
    assign wb_vdmaw_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[29:10] == 20'h4002_1);   // 0x40021000-0x40021fff
    
    assign wb_peri_dat_o  = wb_sys_stb_i   ? wb_sys_dat_o   :
                            wb_vdmaw_stb_i ? wb_vdmaw_dat_o :
                            wb_fmtr_stb_i  ? wb_fmtr_dat_o  :
//                          wb_rgb_stb_i   ? wb_rgb_dat_o   :
                            32'h0000_0000;
    
    assign wb_peri_ack_o  = wb_sys_stb_i   ? wb_sys_ack_o   :
                            wb_vdmaw_stb_i ? wb_vdmaw_ack_o :
                            wb_fmtr_stb_i  ? wb_fmtr_ack_o  :
//                          wb_rgb_stb_i   ? wb_rgb_ack_o   :
                            wb_peri_stb_i;
    
    
    
    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    reg     [31:0]      reg_counter_rxbyteclkhs;
    always @(posedge rxbyteclkhs)   reg_counter_rxbyteclkhs <= reg_counter_rxbyteclkhs + 1;
    
    reg     [31:0]      reg_counter_clk200;
    always @(posedge sys_clk200)    reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    reg     [31:0]      reg_counter_clk100;
    always @(posedge sys_clk100)    reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    reg     [31:0]      reg_counter_peri_aclk;
    always @(posedge axi4l_peri_aclk)   reg_counter_peri_aclk <= reg_counter_peri_aclk + 1;
    
    reg     [31:0]      reg_counter_mem_aclk;
    always @(posedge axi4_mem_aclk) reg_counter_mem_aclk <= reg_counter_mem_aclk + 1;
    
    reg     frame_toggle = 0;
    always @(posedge axi4s_cam_aclk) begin
        if ( axi4s_csi2_tuser[0] && axi4s_csi2_tvalid && axi4s_csi2_tready ) begin
            frame_toggle <= ~frame_toggle;
        end
    end
    
    
    assign led[0] = reg_counter_rxbyteclkhs[24];
    assign led[1] = reg_counter_peri_aclk[24]; // reg_counter_clk200[24];
    assign led[2] = reg_counter_mem_aclk[24];  // reg_counter_clk100[24];
    assign led[3] = cam_gpio;
    
    assign pmod_a[0]   = frame_toggle;
    assign pmod_a[1]   = reg_counter_rxbyteclkhs[5];
    assign pmod_a[2]   = reg_counter_clk200[5];
    assign pmod_a[3]   = reg_counter_clk100[5];
    assign pmod_a[7:4] = 0;
    
    
endmodule


`default_nettype wire

