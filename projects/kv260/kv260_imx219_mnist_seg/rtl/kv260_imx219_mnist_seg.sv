


`timescale 1ns / 1ps
`default_nettype none


module kv260_imx219_mnist_seg
        #(
            parameter   X_WIDTH = 13,
            parameter   Y_WIDTH = 12,
            parameter   X_NUM   = 3280 / 2,
            parameter   Y_NUM   = 2464 / 2
        )
        (
            input   var logic           cam_clk_p,
            input   var logic           cam_clk_n,
            input   var logic   [1:0]   cam_data_p,
            input   var logic   [1:0]   cam_data_n,
            inout   tri logic           cam_scl,
            inout   tri logic           cam_sda,
            output  var logic           cam_enable,

            output  var logic           fan_en,
            output  var logic   [7:0]   pmod
        );
    
    
    // ----------------------------------------
    //  ZynqMP PS
    // ----------------------------------------
    
    logic                               sys_reset;
    logic                               sys_clk100;
    logic                               sys_clk200;
    logic                               sys_clk250;
    
    logic                               dp_video_ref_reset;
    logic                               dp_video_ref_clk;
    logic                               dp_video_out_vsync;
    logic                               dp_video_out_hsync;
    logic   [35:0]                      dp_live_video_in_pixel1;
    
    
    localparam  AXI4L_PERI_ADDR_WIDTH = 40;
    localparam  AXI4L_PERI_DATA_SIZE  = 3;     // 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
    localparam  AXI4L_PERI_DATA_WIDTH = (8 << AXI4L_PERI_DATA_SIZE);
    localparam  AXI4L_PERI_STRB_WIDTH = AXI4L_PERI_DATA_WIDTH / 8;
    
    logic                                axi4l_peri_aresetn;
    logic                                axi4l_peri_aclk;
    logic   [AXI4L_PERI_ADDR_WIDTH-1:0]  axi4l_peri_awaddr;
    logic   [2:0]                        axi4l_peri_awprot;
    logic                                axi4l_peri_awvalid;
    logic                                axi4l_peri_awready;
    logic   [AXI4L_PERI_STRB_WIDTH-1:0]  axi4l_peri_wstrb;
    logic   [AXI4L_PERI_DATA_WIDTH-1:0]  axi4l_peri_wdata;
    logic                                axi4l_peri_wvalid;
    logic                                axi4l_peri_wready;
    logic   [1:0]                        axi4l_peri_bresp;
    logic                                axi4l_peri_bvalid;
    logic                                axi4l_peri_bready;
    logic   [AXI4L_PERI_ADDR_WIDTH-1:0]  axi4l_peri_araddr;
    logic   [2:0]                        axi4l_peri_arprot;
    logic                                axi4l_peri_arvalid;
    logic                                axi4l_peri_arready;
    logic   [AXI4L_PERI_DATA_WIDTH-1:0]  axi4l_peri_rdata;
    logic   [1:0]                        axi4l_peri_rresp;
    logic                                axi4l_peri_rvalid;
    logic                                axi4l_peri_rready;
    
    
    
    localparam  AXI4_MEM_ID_WIDTH   = 6;
    localparam  AXI4_MEM_ADDR_WIDTH = 49;
    localparam  AXI4_MEM_DATA_SIZE  = 4;   // 2:32bit, 3:64bit, 4:128bit
    localparam  AXI4_MEM_DATA_WIDTH = (8 << AXI4_MEM_DATA_SIZE);
    localparam  AXI4_MEM_STRB_WIDTH = AXI4_MEM_DATA_WIDTH / 8;
    
    logic                               axi4_mem_aresetn;
    logic                               axi4_mem_aclk;
    
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem0_awid;
    logic   [AXI4_MEM_ADDR_WIDTH-1:0]   axi4_mem0_awaddr;
    logic   [1:0]                       axi4_mem0_awburst;
    logic   [3:0]                       axi4_mem0_awcache;
    logic   [7:0]                       axi4_mem0_awlen;
    logic   [0:0]                       axi4_mem0_awlock;
    logic   [2:0]                       axi4_mem0_awprot;
    logic   [3:0]                       axi4_mem0_awqos;
    logic   [3:0]                       axi4_mem0_awregion;
    logic   [2:0]                       axi4_mem0_awsize;
    logic                               axi4_mem0_awvalid;
    logic                               axi4_mem0_awready;
    logic   [AXI4_MEM_STRB_WIDTH-1:0]   axi4_mem0_wstrb;
    logic   [AXI4_MEM_DATA_WIDTH-1:0]   axi4_mem0_wdata;
    logic                               axi4_mem0_wlast;
    logic                               axi4_mem0_wvalid;
    logic                               axi4_mem0_wready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem0_bid;
    logic   [1:0]                       axi4_mem0_bresp;
    logic                               axi4_mem0_bvalid;
    logic                               axi4_mem0_bready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem0_arid;
    logic   [AXI4_MEM_ADDR_WIDTH-1:0]   axi4_mem0_araddr;
    logic   [1:0]                       axi4_mem0_arburst;
    logic   [3:0]                       axi4_mem0_arcache;
    logic   [7:0]                       axi4_mem0_arlen;
    logic   [0:0]                       axi4_mem0_arlock;
    logic   [2:0]                       axi4_mem0_arprot;
    logic   [3:0]                       axi4_mem0_arqos;
    logic   [3:0]                       axi4_mem0_arregion;
    logic   [2:0]                       axi4_mem0_arsize;
    logic                               axi4_mem0_arvalid;
    logic                               axi4_mem0_arready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem0_rid;
    logic   [1:0]                       axi4_mem0_rresp;
    logic   [AXI4_MEM_DATA_WIDTH-1:0]   axi4_mem0_rdata;
    logic                               axi4_mem0_rlast;
    logic                               axi4_mem0_rvalid;
    logic                               axi4_mem0_rready;
    
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem1_awid;
    logic   [AXI4_MEM_ADDR_WIDTH-1:0]   axi4_mem1_awaddr;
    logic   [1:0]                       axi4_mem1_awburst;
    logic   [3:0]                       axi4_mem1_awcache;
    logic   [7:0]                       axi4_mem1_awlen;
    logic   [0:0]                       axi4_mem1_awlock;
    logic   [2:0]                       axi4_mem1_awprot;
    logic   [3:0]                       axi4_mem1_awqos;
    logic   [3:0]                       axi4_mem1_awregion;
    logic   [2:0]                       axi4_mem1_awsize;
    logic                               axi4_mem1_awvalid;
    logic                               axi4_mem1_awready;
    logic   [AXI4_MEM_STRB_WIDTH-1:0]   axi4_mem1_wstrb;
    logic   [AXI4_MEM_DATA_WIDTH-1:0]   axi4_mem1_wdata;
    logic                               axi4_mem1_wlast;
    logic                               axi4_mem1_wvalid;
    logic                               axi4_mem1_wready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem1_bid;
    logic   [1:0]                       axi4_mem1_bresp;
    logic                               axi4_mem1_bvalid;
    logic                               axi4_mem1_bready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem1_arid;
    logic   [AXI4_MEM_ADDR_WIDTH-1:0]   axi4_mem1_araddr;
    logic   [1:0]                       axi4_mem1_arburst;
    logic   [3:0]                       axi4_mem1_arcache;
    logic   [7:0]                       axi4_mem1_arlen;
    logic   [0:0]                       axi4_mem1_arlock;
    logic   [2:0]                       axi4_mem1_arprot;
    logic   [3:0]                       axi4_mem1_arqos;
    logic   [3:0]                       axi4_mem1_arregion;
    logic   [2:0]                       axi4_mem1_arsize;
    logic                               axi4_mem1_arvalid;
    logic                               axi4_mem1_arready;
    logic   [AXI4_MEM_ID_WIDTH-1:0]     axi4_mem1_rid;
    logic   [1:0]                       axi4_mem1_rresp;
    logic   [AXI4_MEM_DATA_WIDTH-1:0]   axi4_mem1_rdata;
    logic                               axi4_mem1_rlast;
    logic                               axi4_mem1_rvalid;
    logic                               axi4_mem1_rready;

    logic                               i2c0_scl_i;
    logic                               i2c0_scl_o;
    logic                               i2c0_scl_t;
    logic                               i2c0_sda_i;
    logic                               i2c0_sda_o;
    logic                               i2c0_sda_t;

    design_1
        u_design_1
            (
                .fan_en                     (fan_en),
                
                .out_reset                  (sys_reset),
                .out_clk100                 (sys_clk100),
                .out_clk200                 (sys_clk200),
                .out_clk250                 (sys_clk250),

                .i2c_scl_i                  (i2c0_scl_i),
                .i2c_scl_o                  (i2c0_scl_o),
                .i2c_scl_t                  (i2c0_scl_t),
                .i2c_sda_i                  (i2c0_sda_i),
                .i2c_sda_o                  (i2c0_sda_o),
                .i2c_sda_t                  (i2c0_sda_t),

                .dp_video_ref_reset         (dp_video_ref_reset),
                .dp_video_ref_clk           (dp_video_ref_clk),
                .dp_video_out_vsync         (dp_video_out_vsync),
                .dp_video_out_hsync         (dp_video_out_hsync),
                .dp_live_video_in_pixel1    (dp_live_video_in_pixel1),
                
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
                .m_axi4l_peri_rready        (axi4l_peri_rready),
                
                
                .s_axi4_mem_aresetn         (axi4_mem_aresetn),
                .s_axi4_mem_aclk            (axi4_mem_aclk),
                
                .s_axi4_mem0_awid           (axi4_mem0_awid),
                .s_axi4_mem0_awaddr         (axi4_mem0_awaddr),
                .s_axi4_mem0_awburst        (axi4_mem0_awburst),
                .s_axi4_mem0_awcache        (axi4_mem0_awcache),
                .s_axi4_mem0_awlen          (axi4_mem0_awlen),
                .s_axi4_mem0_awlock         (axi4_mem0_awlock),
                .s_axi4_mem0_awprot         (axi4_mem0_awprot),
                .s_axi4_mem0_awqos          (axi4_mem0_awqos),
    //          .s_axi4_mem0_awregion       (axi4_mem0_awregion),
                .s_axi4_mem0_awsize         (axi4_mem0_awsize),
                .s_axi4_mem0_awvalid        (axi4_mem0_awvalid),
                .s_axi4_mem0_awready        (axi4_mem0_awready),
                .s_axi4_mem0_wstrb          (axi4_mem0_wstrb),
                .s_axi4_mem0_wdata          (axi4_mem0_wdata),
                .s_axi4_mem0_wlast          (axi4_mem0_wlast),
                .s_axi4_mem0_wvalid         (axi4_mem0_wvalid),
                .s_axi4_mem0_wready         (axi4_mem0_wready),
                .s_axi4_mem0_bid            (axi4_mem0_bid),
                .s_axi4_mem0_bresp          (axi4_mem0_bresp),
                .s_axi4_mem0_bvalid         (axi4_mem0_bvalid),
                .s_axi4_mem0_bready         (axi4_mem0_bready),
                .s_axi4_mem0_araddr         (axi4_mem0_araddr),
                .s_axi4_mem0_arburst        (axi4_mem0_arburst),
                .s_axi4_mem0_arcache        (axi4_mem0_arcache),
                .s_axi4_mem0_arid           (axi4_mem0_arid),
                .s_axi4_mem0_arlen          (axi4_mem0_arlen),
                .s_axi4_mem0_arlock         (axi4_mem0_arlock),
                .s_axi4_mem0_arprot         (axi4_mem0_arprot),
                .s_axi4_mem0_arqos          (axi4_mem0_arqos),
    //          .s_axi4_mem0_arregion       (axi4_mem0_arregion),
                .s_axi4_mem0_arsize         (axi4_mem0_arsize),
                .s_axi4_mem0_arvalid        (axi4_mem0_arvalid),
                .s_axi4_mem0_arready        (axi4_mem0_arready),
                .s_axi4_mem0_rid            (axi4_mem0_rid),
                .s_axi4_mem0_rresp          (axi4_mem0_rresp),
                .s_axi4_mem0_rdata          (axi4_mem0_rdata),
                .s_axi4_mem0_rlast          (axi4_mem0_rlast),
                .s_axi4_mem0_rvalid         (axi4_mem0_rvalid),
                .s_axi4_mem0_rready         (axi4_mem0_rready),

                .s_axi4_mem1_awid           (axi4_mem1_awid),
                .s_axi4_mem1_awaddr         (axi4_mem1_awaddr),
                .s_axi4_mem1_awburst        (axi4_mem1_awburst),
                .s_axi4_mem1_awcache        (axi4_mem1_awcache),
                .s_axi4_mem1_awlen          (axi4_mem1_awlen),
                .s_axi4_mem1_awlock         (axi4_mem1_awlock),
                .s_axi4_mem1_awprot         (axi4_mem1_awprot),
                .s_axi4_mem1_awqos          (axi4_mem1_awqos),
    //          .s_axi4_mem1_awregion       (axi4_mem1_awregion),
                .s_axi4_mem1_awsize         (axi4_mem1_awsize),
                .s_axi4_mem1_awvalid        (axi4_mem1_awvalid),
                .s_axi4_mem1_awready        (axi4_mem1_awready),
                .s_axi4_mem1_wstrb          (axi4_mem1_wstrb),
                .s_axi4_mem1_wdata          (axi4_mem1_wdata),
                .s_axi4_mem1_wlast          (axi4_mem1_wlast),
                .s_axi4_mem1_wvalid         (axi4_mem1_wvalid),
                .s_axi4_mem1_wready         (axi4_mem1_wready),
                .s_axi4_mem1_bid            (axi4_mem1_bid),
                .s_axi4_mem1_bresp          (axi4_mem1_bresp),
                .s_axi4_mem1_bvalid         (axi4_mem1_bvalid),
                .s_axi4_mem1_bready         (axi4_mem1_bready),
                .s_axi4_mem1_araddr         (axi4_mem1_araddr),
                .s_axi4_mem1_arburst        (axi4_mem1_arburst),
                .s_axi4_mem1_arcache        (axi4_mem1_arcache),
                .s_axi4_mem1_arid           (axi4_mem1_arid),
                .s_axi4_mem1_arlen          (axi4_mem1_arlen),
                .s_axi4_mem1_arlock         (axi4_mem1_arlock),
                .s_axi4_mem1_arprot         (axi4_mem1_arprot),
                .s_axi4_mem1_arqos          (axi4_mem1_arqos),
    //          .s_axi4_mem1_arregion       (axi4_mem1_arregion),
                .s_axi4_mem1_arsize         (axi4_mem1_arsize),
                .s_axi4_mem1_arvalid        (axi4_mem1_arvalid),
                .s_axi4_mem1_arready        (axi4_mem1_arready),
                .s_axi4_mem1_rid            (axi4_mem1_rid),
                .s_axi4_mem1_rresp          (axi4_mem1_rresp),
                .s_axi4_mem1_rdata          (axi4_mem1_rdata),
                .s_axi4_mem1_rlast          (axi4_mem1_rlast),
                .s_axi4_mem1_rvalid         (axi4_mem1_rvalid),
                .s_axi4_mem1_rready         (axi4_mem1_rready)
            );
    
    IOBUF
        i_iobuf_i2c0_scl
            (
                .I                      (i2c0_scl_o),
                .O                      (i2c0_scl_i),
                .T                      (i2c0_scl_t),
                .IO                     (cam_scl)
        );

    IOBUF
        i_iobuf_i2c0_sda
            (
                .I                      (i2c0_sda_o),
                .O                      (i2c0_sda_i),
                .T                      (i2c0_sda_t),
                .IO                     (cam_sda)
            );
    
    
    // AXI4L => WISHBONE
    localparam  WB_ADR_WIDTH = AXI4L_PERI_ADDR_WIDTH - AXI4L_PERI_DATA_SIZE;
    localparam  WB_DAT_WIDTH = AXI4L_PERI_DATA_WIDTH;
    localparam  WB_SEL_WIDTH = AXI4L_PERI_STRB_WIDTH;
    
    logic                          wb_peri_rst_i;
    logic                          wb_peri_clk_i;
    logic   [WB_ADR_WIDTH-1:0]     wb_peri_adr_i;
    logic   [WB_DAT_WIDTH-1:0]     wb_peri_dat_o;
    logic   [WB_DAT_WIDTH-1:0]     wb_peri_dat_i;
    logic   [WB_SEL_WIDTH-1:0]     wb_peri_sel_i;
    logic                          wb_peri_we_i;
    logic                          wb_peri_stb_i;
    logic                          wb_peri_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH           (AXI4L_PERI_ADDR_WIDTH),
                .AXI4L_DATA_SIZE            (AXI4L_PERI_DATA_SIZE)     // 0:8bit, 1:16bit, 2:32bit ...
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
    
    logic   [WB_DAT_WIDTH-1:0]  wb_gid_dat_o;
    logic                       wb_gid_stb_i;
    logic                       wb_gid_ack_o;
        
    reg     reg_sw_reset;
    reg     reg_cam_enable;
    always_ff @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_sw_reset   <= 1'b0;
            reg_cam_enable <= 1'b0;
        end
        else begin
            if ( wb_gid_stb_i && wb_peri_we_i ) begin
                case ( wb_peri_adr_i[3:0] )
                1: reg_sw_reset   <= wb_peri_dat_i;
                2: reg_cam_enable <= wb_peri_dat_i;
                endcase
            end
        end
    end
    
    assign wb_gid_dat_o = wb_peri_adr_i[3:0] == 0 ? 32'h01234567   :
                          wb_peri_adr_i[3:0] == 1 ? reg_sw_reset   :
                          wb_peri_adr_i[3:0] == 2 ? reg_cam_enable : 0;
    assign wb_gid_ack_o = wb_gid_stb_i;

    assign cam_enable = reg_cam_enable;
    
    
    
    // ----------------------------------------
    //  MIPI D-PHY RX
    // ----------------------------------------
    
    (* KEEP = "true" *)
    logic               rxbyteclkhs;
    logic               clkoutphy_out;
    logic               pll_lock_out;
    logic               system_rst_out;
    logic               init_done;
    
    logic               cl_rxclkactivehs;
    logic               cl_stopstate;
    logic               cl_enable         = 1;
    logic               cl_rxulpsclknot;
    logic               cl_ulpsactivenot;
    
    logic   [7:0]       dl0_rxdatahs;
    logic               dl0_rxvalidhs;
    logic               dl0_rxactivehs;
    logic               dl0_rxsynchs;
    
    logic               dl0_forcerxmode   = 0;
    logic               dl0_stopstate;
    logic               dl0_enable        = 1;
    logic               dl0_ulpsactivenot;
    
    logic               dl0_rxclkesc;
    logic               dl0_rxlpdtesc;
    logic               dl0_rxulpsesc;
    logic   [3:0]       dl0_rxtriggeresc;
    logic   [7:0]       dl0_rxdataesc;
    logic               dl0_rxvalidesc;
    
    logic               dl0_errsoths;
    logic               dl0_errsotsynchs;
    logic               dl0_erresc;
    logic               dl0_errsyncesc;
    logic               dl0_errcontrol;
    
    logic   [7:0]       dl1_rxdatahs;
    logic               dl1_rxvalidhs;
    logic               dl1_rxactivehs;
    logic               dl1_rxsynchs;
    
    logic               dl1_forcerxmode   = 0;
    logic               dl1_stopstate;
    logic               dl1_enable        = 1;
    logic               dl1_ulpsactivenot;
    
    logic               dl1_rxclkesc;
    logic               dl1_rxlpdtesc;
    logic               dl1_rxulpsesc;
    logic   [3:0]       dl1_rxtriggeresc;
    logic   [7:0]       dl1_rxdataesc;
    logic               dl1_rxvalidesc;
    
    logic               dl1_errsoths;
    logic               dl1_errsotsynchs;
    logic               dl1_erresc;
    logic               dl1_errsyncesc;
    logic               dl1_errcontrol;
    
    mipi_dphy_cam
        i_mipi_dphy_cam
            (
                .core_clk                   (sys_clk200),
                .core_rst                   (sys_reset | reg_sw_reset),
                .rxbyteclkhs                (rxbyteclkhs),
                
                .clkoutphy_out              (clkoutphy_out),
                .pll_lock_out               (pll_lock_out),
                .system_rst_out             (system_rst_out),
                .init_done                  (init_done),
                
                .cl_rxclkactivehs           (cl_rxclkactivehs),
                .cl_stopstate               (cl_stopstate),
                .cl_enable                  (cl_enable),
                .cl_rxulpsclknot            (cl_rxulpsclknot),
                .cl_ulpsactivenot           (cl_ulpsactivenot),
                
                .dl0_rxdatahs               (dl0_rxdatahs),
                .dl0_rxvalidhs              (dl0_rxvalidhs),
                .dl0_rxactivehs             (dl0_rxactivehs),
                .dl0_rxsynchs               (dl0_rxsynchs),
                
                .dl0_forcerxmode            (dl0_forcerxmode),
                .dl0_stopstate              (dl0_stopstate),
                .dl0_enable                 (dl0_enable),
                .dl0_ulpsactivenot          (dl0_ulpsactivenot),
                
                .dl0_rxclkesc               (dl0_rxclkesc),
                .dl0_rxlpdtesc              (dl0_rxlpdtesc),
                .dl0_rxulpsesc              (dl0_rxulpsesc),
                .dl0_rxtriggeresc           (dl0_rxtriggeresc),
                .dl0_rxdataesc              (dl0_rxdataesc),
                .dl0_rxvalidesc             (dl0_rxvalidesc),
                
                .dl0_errsoths               (dl0_errsoths),
                .dl0_errsotsynchs           (dl0_errsotsynchs),
                .dl0_erresc                 (dl0_erresc),
                .dl0_errsyncesc             (dl0_errsyncesc),
                .dl0_errcontrol             (dl0_errcontrol),
                
                .dl1_rxdatahs               (dl1_rxdatahs),
                .dl1_rxvalidhs              (dl1_rxvalidhs),
                .dl1_rxactivehs             (dl1_rxactivehs),
                .dl1_rxsynchs               (dl1_rxsynchs),
                
                .dl1_forcerxmode            (dl1_forcerxmode),
                .dl1_stopstate              (dl1_stopstate),
                .dl1_enable                 (dl1_enable),
                .dl1_ulpsactivenot          (dl1_ulpsactivenot),
                
                .dl1_rxclkesc               (dl1_rxclkesc),
                .dl1_rxlpdtesc              (dl1_rxlpdtesc),
                .dl1_rxulpsesc              (dl1_rxulpsesc),
                .dl1_rxtriggeresc           (dl1_rxtriggeresc),
                .dl1_rxdataesc              (dl1_rxdataesc),
                .dl1_rxvalidesc             (dl1_rxvalidesc),
                
                .dl1_errsoths               (dl1_errsoths),
                .dl1_errsotsynchs           (dl1_errsotsynchs),
                .dl1_erresc                 (dl1_erresc),
                .dl1_errsyncesc             (dl1_errsyncesc),
                .dl1_errcontrol             (dl1_errcontrol),
                
                .clk_rxp                    (cam_clk_p),
                .clk_rxn                    (cam_clk_n),
                .data_rxp                   (cam_data_p),
                .data_rxn                   (cam_data_n)
           );
    
    logic       dphy_clk   = rxbyteclkhs;
    logic       dphy_reset = system_rst_out;
    
    
    
    // ----------------------------------------
    //  CSI-2
    // ----------------------------------------
    
    
    logic           axi4s_cam_aresetn;
    logic           axi4s_cam_aclk   ;
    assign axi4s_cam_aresetn = ~sys_reset;
    assign axi4s_cam_aclk    = sys_clk200;
    
    logic   [0:0]   axi4s_csi2_tuser;
    logic           axi4s_csi2_tlast;
    logic   [9:0]   axi4s_csi2_tdata;
    logic           axi4s_csi2_tvalid;
    logic           axi4s_csi2_tready;
    
    logic           mipi_ecc_corrected;
    logic           mipi_ecc_error;
    logic           mipi_ecc_valid;
    logic           mipi_crc_error;
    logic           mipi_crc_valid;
    logic           mipi_packet_lost;
    logic           mipi_fifo_overflow;
    
    jelly2_mipi_csi2_rx
            #(
                .LANES                      (2),
                .DATA_WIDTH                 (10),
                .M_FIFO_ASYNC               (1),
                .M_FIFO_PTR_WIDTH           (10)
            )
        u_mipi_csi2_rx
            (
                .aresetn                    (~sys_reset),
                .aclk                       (sys_clk250),
                
                .ecc_corrected              (mipi_ecc_corrected),
                .ecc_error                  (mipi_ecc_error),
                .ecc_valid                  (mipi_ecc_valid),
                .crc_error                  (mipi_crc_error),
                .crc_valid                  (mipi_crc_valid),
                .packet_lost                (mipi_packet_lost),
                .fifo_overflow              (mipi_fifo_overflow),
                
                .rxreseths                  (dphy_reset),
                .rxbyteclkhs                (dphy_clk),
                .rxdatahs                   ({dl1_rxdatahs,   dl0_rxdatahs  }),
                .rxvalidhs                  ({dl1_rxvalidhs,  dl0_rxvalidhs }),
                .rxactivehs                 ({dl1_rxactivehs, dl0_rxactivehs}),
                .rxsynchs                   ({dl1_rxsynchs,   dl0_rxsynchs  }),
                
                .m_axi4s_aresetn            (axi4s_cam_aresetn),
                .m_axi4s_aclk               (axi4s_cam_aclk),
                .m_axi4s_tuser              (axi4s_csi2_tuser),
                .m_axi4s_tlast              (axi4s_csi2_tlast),
                .m_axi4s_tdata              (axi4s_csi2_tdata),
                .m_axi4s_tvalid             (axi4s_csi2_tvalid),
                .m_axi4s_tready             (1'b1)  // (axi4s_csi2_tready)
            );
    
    
    // format regularizer
    logic   [X_WIDTH-1:0]       fmtr_param_width;
    logic   [Y_WIDTH-1:0]       fmtr_param_height;
    
    logic   [0:0]               axi4s_fmtr_tuser;
    logic                       axi4s_fmtr_tlast;
    logic   [9:0]               axi4s_fmtr_tdata;
    logic                       axi4s_fmtr_tvalid;
    logic                       axi4s_fmtr_tready;

    logic   [WB_DAT_WIDTH-1:0]  wb_fmtr_dat_o;
    logic                       wb_fmtr_stb_i;
    logic                       wb_fmtr_ack_o;
    
    jelly2_video_format_regularizer
            #(
                .WB_ADR_WIDTH               (8),
                .WB_DAT_WIDTH               (WB_DAT_WIDTH),
                
                .TUSER_WIDTH                (1),
                .TDATA_WIDTH                (10),
                .X_WIDTH                    (X_WIDTH),
                .Y_WIDTH                    (Y_WIDTH),
                .TIMER_WIDTH                (32),
                .S_SLAVE_REGS               (1),
                .S_MASTER_REGS              (1),
                .M_SLAVE_REGS               (1),
                .M_MASTER_REGS              (1),
                
                .INIT_CTL_CONTROL           (2'b00),
                .INIT_CTL_SKIP              (1),
                .INIT_PARAM_WIDTH           (X_NUM),
                .INIT_PARAM_HEIGHT          (Y_NUM),
                .INIT_PARAM_FILL            (10'd0),
                .INIT_PARAM_TIMEOUT         (32'h00010000)
            )
        u_video_format_regularizer
            (
                .aresetn                    (axi4s_cam_aresetn),
                .aclk                       (axi4s_cam_aclk),
                .aclken                     (1'b1),

                .out_param_width            (fmtr_param_width),
                .out_param_height           (fmtr_param_height),

                .s_axi4s_tuser              (axi4s_csi2_tuser),
                .s_axi4s_tlast              (axi4s_csi2_tlast),
                .s_axi4s_tdata              (axi4s_csi2_tdata),
                .s_axi4s_tvalid             (axi4s_csi2_tvalid),
                .s_axi4s_tready             (axi4s_csi2_tready),
                
                .m_axi4s_tuser              (axi4s_fmtr_tuser),
                .m_axi4s_tlast              (axi4s_fmtr_tlast),
                .m_axi4s_tdata              (axi4s_fmtr_tdata),
                .m_axi4s_tvalid             (axi4s_fmtr_tvalid),
                .m_axi4s_tready             (axi4s_fmtr_tready),

                .s_wb_rst_i                 (wb_peri_rst_i),
                .s_wb_clk_i                 (wb_peri_clk_i),
                .s_wb_adr_i                 (wb_peri_adr_i[7:0]),
                .s_wb_dat_o                 (wb_fmtr_dat_o),
                .s_wb_dat_i                 (wb_peri_dat_i),
                .s_wb_we_i                  (wb_peri_we_i),
                .s_wb_sel_i                 (wb_peri_sel_i),
                .s_wb_stb_i                 (wb_fmtr_stb_i),
                .s_wb_ack_o                 (wb_fmtr_ack_o)
            );
    

    // 現像
    wire	[0:0]		axi4s_rgb_tuser;
    wire				axi4s_rgb_tlast;
    wire	[39:0]		axi4s_rgb_tdata;
    wire				axi4s_rgb_tvalid;
    wire				axi4s_rgb_tready;

    wire	[31:0]		wb_rgb_dat_o;
    wire				wb_rgb_stb_i;
    wire				wb_rgb_ack_o;

    video_raw_to_rgb
            #(
                .WB_ADR_WIDTH               (17),
                .WB_DAT_WIDTH               (WB_DAT_WIDTH),

                .S_DATA_WIDTH               (10),
                .M_DATA_WIDTH               (8),
                
                .X_WIDTH                    (X_WIDTH),
                .Y_WIDTH                    (Y_WIDTH),
                .IMG_Y_NUM                  (1080),
                
                .TUSER_WIDTH                (1)
            )
        u_video_raw_to_rgb
            (
                .aresetn                    (axi4s_cam_aresetn),
                .aclk                       (axi4s_cam_aclk),

                .param_width                (fmtr_param_width),
                .param_height               (fmtr_param_height),

                .in_update_req              (1'b1),
                
                .s_wb_rst_i                 (wb_peri_rst_i),
                .s_wb_clk_i                 (wb_peri_clk_i),
                .s_wb_adr_i                 (wb_peri_adr_i[16:0]),
                .s_wb_dat_o                 (wb_rgb_dat_o),
                .s_wb_dat_i                 (wb_peri_dat_i),
                .s_wb_we_i                  (wb_peri_we_i),
                .s_wb_sel_i                 (wb_peri_sel_i),
                .s_wb_stb_i                 (wb_rgb_stb_i),
                .s_wb_ack_o                 (wb_rgb_ack_o),
                
                .s_axi4s_tuser              (axi4s_fmtr_tuser),
                .s_axi4s_tlast              (axi4s_fmtr_tlast),
                .s_axi4s_tdata              (axi4s_fmtr_tdata),
                .s_axi4s_tvalid             (axi4s_fmtr_tvalid),
                .s_axi4s_tready             (axi4s_fmtr_tready),
                
                .m_axi4s_tuser              (axi4s_rgb_tuser),
                .m_axi4s_tlast              (axi4s_rgb_tlast),
                .m_axi4s_tdata              (axi4s_rgb_tdata),
                .m_axi4s_tvalid             (axi4s_rgb_tvalid),
                .m_axi4s_tready             (axi4s_rgb_tready)
            );
    
    
    
    
    // -----------------------------------------
    //  Video DMA Write
    // -----------------------------------------
    
    logic   [WB_DAT_WIDTH-1:0]          wb_vdmaw_dat_o;
    logic                               wb_vdmaw_stb_i;
    logic                               wb_vdmaw_ack_o;
    
    jelly2_dma_video_write
            #(
                .WB_ASYNC                   (1),
                .WB_ADR_WIDTH               (8),
                .WB_DAT_WIDTH               (WB_DAT_WIDTH),
                
                .AXI4S_ASYNC                (1),
                .AXI4S_DATA_WIDTH           (32),
                .AXI4S_USER_WIDTH           (1),
                
                .AXI4_ID_WIDTH              (AXI4_MEM_ID_WIDTH),
                .AXI4_ADDR_WIDTH            (AXI4_MEM_ADDR_WIDTH),
                .AXI4_DATA_SIZE             (AXI4_MEM_DATA_SIZE),
                .AXI4_LEN_WIDTH             (8),
                .AXI4_QOS_WIDTH             (4),
                
                .INDEX_WIDTH                (1),
                .SIZE_OFFSET                (1'b1),
                .H_SIZE_WIDTH               (12),
                .V_SIZE_WIDTH               (12),
                .F_SIZE_WIDTH               (8),
                .LINE_STEP_WIDTH            (AXI4_MEM_ADDR_WIDTH),
                .FRAME_STEP_WIDTH           (AXI4_MEM_ADDR_WIDTH),
                
                .INIT_CTL_CONTROL           (4'b0000),
                .INIT_IRQ_ENABLE            (1'b0),
                .INIT_PARAM_ADDR            (0),
                .INIT_PARAM_AWLEN_MAX       (255),
                .INIT_PARAM_H_SIZE          (X_NUM-1),
                .INIT_PARAM_V_SIZE          (Y_NUM-1),
                .INIT_PARAM_LINE_STEP       (8192),
                .INIT_PARAM_F_SIZE          (0),
                .INIT_PARAM_FRAME_STEP      (Y_NUM*8192),
                .INIT_SKIP_EN               (1'b1),
                .INIT_DETECT_FIRST          (3'b010),
                .INIT_DETECT_LAST           (3'b001),
                .INIT_PADDING_EN            (1'b1),
                .INIT_PADDING_DATA          (32'd0),
                
                .BYPASS_GATE                (0),
                .BYPASS_ALIGN               (0),
                .DETECTOR_ENABLE            (1),
                .ALLOW_UNALIGNED            (1), // (0),
                .CAPACITY_WIDTH             (32),
                
                .WFIFO_PTR_WIDTH            (9),
                .WFIFO_RAM_TYPE             ("block")
            )
        u_dma_video_write
            (
                .endian                     (1'b0),
                
                .s_wb_rst_i                 (wb_peri_rst_i),
                .s_wb_clk_i                 (wb_peri_clk_i),
                .s_wb_adr_i                 (wb_peri_adr_i[7:0]),
                .s_wb_dat_i                 (wb_peri_dat_i),
                .s_wb_dat_o                 (wb_vdmaw_dat_o),
                .s_wb_we_i                  (wb_peri_we_i),
                .s_wb_sel_i                 (wb_peri_sel_i),
                .s_wb_stb_i                 (wb_vdmaw_stb_i),
                .s_wb_ack_o                 (wb_vdmaw_ack_o),
                .out_irq                    (),
                
                .buffer_request             (),
                .buffer_release             (),
                .buffer_addr                ('0),
                
                .s_axi4s_aresetn            (axi4s_cam_aresetn),
                .s_axi4s_aclk               (axi4s_cam_aclk),
                .s_axi4s_tuser              (axi4s_rgb_tuser),
                .s_axi4s_tlast              (axi4s_rgb_tlast),
                .s_axi4s_tdata              (axi4s_rgb_tdata),
                .s_axi4s_tvalid             (axi4s_rgb_tvalid),
                .s_axi4s_tready             (axi4s_rgb_tready),
                
                .m_aresetn                  (axi4_mem_aresetn),
                .m_aclk                     (axi4_mem_aclk),
                .m_axi4_awid                (axi4_mem0_awid),
                .m_axi4_awaddr              (axi4_mem0_awaddr),
                .m_axi4_awburst             (axi4_mem0_awburst),
                .m_axi4_awcache             (axi4_mem0_awcache),
                .m_axi4_awlen               (axi4_mem0_awlen),
                .m_axi4_awlock              (axi4_mem0_awlock),
                .m_axi4_awprot              (axi4_mem0_awprot),
                .m_axi4_awqos               (axi4_mem0_awqos),
                .m_axi4_awregion            (),
                .m_axi4_awsize              (axi4_mem0_awsize),
                .m_axi4_awvalid             (axi4_mem0_awvalid),
                .m_axi4_awready             (axi4_mem0_awready),
                .m_axi4_wstrb               (axi4_mem0_wstrb),
                .m_axi4_wdata               (axi4_mem0_wdata),
                .m_axi4_wlast               (axi4_mem0_wlast),
                .m_axi4_wvalid              (axi4_mem0_wvalid),
                .m_axi4_wready              (axi4_mem0_wready),
                .m_axi4_bid                 (axi4_mem0_bid),
                .m_axi4_bresp               (axi4_mem0_bresp),
                .m_axi4_bvalid              (axi4_mem0_bvalid),
                .m_axi4_bready              (axi4_mem0_bready)
            );
    
    
    
    
    // -----------------------------------------
    //  Read
    // -----------------------------------------
    
    
    localparam  VOUT_X_NUM = 1920;
    localparam  VOUT_Y_NUM = 1080;
    
    
    logic   [23:0]                      axi4s_vout_tdata;
    logic                               axi4s_vout_tlast;
    logic   [0:0]                       axi4s_vout_tuser;
    logic                               axi4s_vout_tvalid;
    logic                               axi4s_vout_tready;
    
    
    logic   [WB_DAT_WIDTH-1:0]          wb_vdmar_dat_o;
    logic                               wb_vdmar_stb_i;
    logic                               wb_vdmar_ack_o;
    
    jelly2_dma_video_read
            #(
                .WB_ASYNC                   (1),
                .WB_ADR_WIDTH               (8),
                .WB_DAT_WIDTH               (WB_DAT_WIDTH),
                
                .AXI4S_ASYNC                (1),
                .AXI4S_DATA_WIDTH           (24), // (32),
                .AXI4S_USER_WIDTH           (1),
                
                .AXI4_ID_WIDTH              (AXI4_MEM_ID_WIDTH),
                .AXI4_ADDR_WIDTH            (AXI4_MEM_ADDR_WIDTH),
                .AXI4_DATA_SIZE             (AXI4_MEM_DATA_SIZE),
                .AXI4_LEN_WIDTH             (8),
                .AXI4_QOS_WIDTH             (4),
                
                .INDEX_WIDTH                (1),
                .SIZE_OFFSET                (1'b1),
                .H_SIZE_WIDTH               (12),
                .V_SIZE_WIDTH               (12),
                .F_SIZE_WIDTH               (8),
                .LINE_STEP_WIDTH            (AXI4_MEM_ADDR_WIDTH),
                .FRAME_STEP_WIDTH           (AXI4_MEM_ADDR_WIDTH),
                
                .INIT_CTL_CONTROL           (4'b0000),
                .INIT_IRQ_ENABLE            (1'b0),
                .INIT_PARAM_ADDR            (0),
                .INIT_PARAM_ARLEN_MAX       (255),
                .INIT_PARAM_H_SIZE          (VOUT_X_NUM-1),
                .INIT_PARAM_V_SIZE          (VOUT_Y_NUM-1),
                .INIT_PARAM_LINE_STEP       (8192),
                .INIT_PARAM_F_SIZE          (0),
                .INIT_PARAM_FRAME_STEP      (VOUT_Y_NUM*8192),
                
                .BYPASS_GATE                (0),
                .BYPASS_ALIGN               (0),
                .ALLOW_UNALIGNED            (0),
                .CAPACITY_WIDTH             (32),
                .RFIFO_PTR_WIDTH            (10),
                .RFIFO_RAM_TYPE             ("block")
            )
        u_dma_video_read
            (
                .endian                     (1'b0),
                
                .s_wb_rst_i                 (wb_peri_rst_i),
                .s_wb_clk_i                 (wb_peri_clk_i),
                .s_wb_adr_i                 (wb_peri_adr_i[7:0]),
                .s_wb_dat_i                 (wb_peri_dat_i),
                .s_wb_dat_o                 (wb_vdmar_dat_o),
                .s_wb_we_i                  (wb_peri_we_i),
                .s_wb_sel_i                 (wb_peri_sel_i),
                .s_wb_stb_i                 (wb_vdmar_stb_i),
                .s_wb_ack_o                 (wb_vdmar_ack_o),
                .out_irq                    (),
                
                .buffer_request             (),
                .buffer_release             (),
                .buffer_addr                ('0),
                
                .m_axi4s_aresetn            (~vout_reset),
                .m_axi4s_aclk               (vout_clk),
                .m_axi4s_tdata              (axi4s_vout_tdata),
                .m_axi4s_tlast              (axi4s_vout_tlast),
                .m_axi4s_tuser              (axi4s_vout_tuser),
                .m_axi4s_tvalid             (axi4s_vout_tvalid),
                .m_axi4s_tready             (axi4s_vout_tready),
                
                .m_aresetn                  (axi4_mem_aresetn),
                .m_aclk                     (axi4_mem_aclk),
                .m_axi4_arid                (axi4_mem0_arid),
                .m_axi4_araddr              (axi4_mem0_araddr),
                .m_axi4_arlen               (axi4_mem0_arlen),
                .m_axi4_arsize              (axi4_mem0_arsize),
                .m_axi4_arburst             (axi4_mem0_arburst),
                .m_axi4_arlock              (axi4_mem0_arlock),
                .m_axi4_arcache             (axi4_mem0_arcache),
                .m_axi4_arprot              (axi4_mem0_arprot),
                .m_axi4_arqos               (axi4_mem0_arqos),
                .m_axi4_arregion            (axi4_mem0_arregion),
                .m_axi4_arvalid             (axi4_mem0_arvalid),
                .m_axi4_arready             (axi4_mem0_arready),
                .m_axi4_rid                 (axi4_mem0_rid),
                .m_axi4_rdata               (axi4_mem0_rdata),
                .m_axi4_rresp               (axi4_mem0_rresp),
                .m_axi4_rlast               (axi4_mem0_rlast),
                .m_axi4_rvalid              (axi4_mem0_rvalid),
                .m_axi4_rready              (axi4_mem0_rready)
            );
    
    
    
    // ----------------------------------------
    //  VOUT
    // ----------------------------------------
    
    logic                       vout_reset;
    logic                       vout_clk  ;
    assign  vout_reset = dp_video_ref_reset;
    assign  vout_clk   = dp_video_ref_clk;
    
    logic                       vout_vsgen_vsync;
    logic                       vout_vsgen_hsync;
    logic                       vout_vsgen_de;
    
    logic   [WB_DAT_WIDTH-1:0]  wb_vsgen_dat_o;
    logic                       wb_vsgen_stb_i;
    logic                       wb_vsgen_ack_o;
    
    jelly_vsync_adjust_de
            #(
                .USER_WIDTH              (0),
                .H_COUNT_WIDTH           (14),
                .V_COUNT_WIDTH           (14),
                
                .WB_ADR_WIDTH            (8),
                .WB_DAT_WIDTH            (WB_DAT_WIDTH),
                
                .INIT_CTL_CONTROL        (2'b00),
                .INIT_PARAM_HSIZE        (1920-1),
                .INIT_PARAM_VSIZE        (1080-1),
                .INIT_PARAM_HSTART       (131),
                .INIT_PARAM_VSTART       (35),
                .INIT_PARAM_HPOL         (1),
                .INIT_PARAM_VPOL         (1)
            )
        u_vsync_adjust_de
            (
                .reset                  (vout_reset),
                .clk                    (vout_clk),
                
                .in_update_req          (1'b1),
                
                .s_wb_rst_i             (wb_peri_rst_i),
                .s_wb_clk_i             (wb_peri_clk_i),
                .s_wb_adr_i             (wb_peri_adr_i[7:0]),
                .s_wb_dat_o             (wb_vsgen_dat_o),
                .s_wb_dat_i             (wb_peri_dat_i),
                .s_wb_we_i              (wb_peri_we_i),
                .s_wb_sel_i             (wb_peri_sel_i),
                .s_wb_stb_i             (wb_vsgen_stb_i),
                .s_wb_ack_o             (wb_vsgen_ack_o),
                
                .in_vsync               (dp_video_out_vsync),
                .in_hsync               (dp_video_out_hsync),
                .in_user                (1'b0),
                
                .out_vsync              (vout_vsgen_vsync),
                .out_hsync              (vout_vsgen_hsync),
                .out_de                 (vout_vsgen_de),
                .out_user               ()
            );
    
    // vout
    logic           vout_vsync;
    logic           vout_hsync;
    logic           vout_de;
    logic   [23:0]  vout_data;
    logic   [3:0]   vout_ctl;
    
    jelly_vout_axi4s
            #(
                .WIDTH                      (24)
            )
        u_vout_axi4s
            (
                .reset                      (vout_reset),
                .clk                        (vout_clk),
                
                .s_axi4s_tuser              (axi4s_vout_tuser),
                .s_axi4s_tlast              (axi4s_vout_tlast),
                .s_axi4s_tdata              (axi4s_vout_tdata[23:0]),
                .s_axi4s_tvalid             (axi4s_vout_tvalid),
                .s_axi4s_tready             (axi4s_vout_tready),
                
                .in_vsync                   (vout_vsgen_vsync),
                .in_hsync                   (vout_vsgen_hsync),
                .in_de                      (vout_vsgen_de),
                .in_ctl                     ('0),
                .in_data                    ('0),
                
                .out_vsync                  (vout_vsync),
                .out_hsync                  (vout_hsync),
                .out_de                     (vout_de),
                .out_data                   (vout_data),
                .out_ctl                    (vout_ctl)
            );
    
    assign dp_live_video_in_pixel1[11:0]  = {vout_data[15: 8], vout_data[15:12]};
    assign dp_live_video_in_pixel1[23:12] = {vout_data[23:16], vout_data[23:20]};
    assign dp_live_video_in_pixel1[35:24] = {vout_data[ 7: 0], vout_data[ 7: 4]};
    
    
    
    // ----------------------------------------
    //  WISHBONE address decoder
    // ----------------------------------------
    
    assign wb_gid_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h000);   // 0x80000000-0x8000ffff
    assign wb_fmtr_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h010);   // 0x80100000-0x8010ffff
    assign wb_rgb_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:17] ==  8'h02);    // 0x80120000-0x8012ffff
    assign wb_vdmaw_stb_i = wb_peri_stb_i & (wb_peri_adr_i[25:13] == 12'h032);   // 0x80320000-0x8032ffff
    assign wb_vdmar_stb_i = wb_peri_stb_i & (wb_peri_adr_i[25:13] == 12'h034);   // 0x80340000-0x8034ffff
    assign wb_vsgen_stb_i = wb_peri_stb_i & (wb_peri_adr_i[25:13] == 12'h036);   // 0x80360000-0x8036ffff
    
    assign wb_peri_dat_o  = wb_gid_stb_i   ? wb_gid_dat_o   :
                            wb_fmtr_stb_i  ? wb_fmtr_dat_o  :
                            wb_rgb_stb_i   ? wb_rgb_dat_o   :
                            wb_vdmaw_stb_i ? wb_vdmaw_dat_o :
                            wb_vdmar_stb_i ? wb_vdmar_dat_o :
                            wb_vsgen_stb_i ? wb_vsgen_dat_o :
                            32'h0000_0000;
    
    assign wb_peri_ack_o  = wb_gid_stb_i   ? wb_gid_ack_o   :
                            wb_vdmaw_stb_i ? wb_vdmaw_ack_o :
                            wb_fmtr_stb_i  ? wb_fmtr_ack_o  :
                            wb_rgb_stb_i   ? wb_rgb_ack_o   :
                            wb_vdmar_stb_i ? wb_vdmar_ack_o :
                            wb_vsgen_stb_i ? wb_vsgen_ack_o :
                            wb_peri_stb_i;
    
    
    
    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    logic   [31:0]      reg_counter_rxbyteclkhs;
    always_ff @(posedge rxbyteclkhs)   reg_counter_rxbyteclkhs <= reg_counter_rxbyteclkhs + 1;
    
    logic   [31:0]      reg_counter_clk100;
    always_ff @(posedge sys_clk100)    reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    logic   [31:0]      reg_counter_clk200;
    always_ff @(posedge sys_clk200)    reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    logic   [31:0]      reg_counter_clk250;
    always_ff @(posedge sys_clk250)    reg_counter_clk250 <= reg_counter_clk250 + 1;
    
    logic   frame_toggle = 0;
    always_ff @(posedge axi4s_cam_aclk) begin
        if ( axi4s_csi2_tuser[0] && axi4s_csi2_tvalid && axi4s_csi2_tready ) begin
            frame_toggle <= ~frame_toggle;
        end
    end
    
    
    logic   [31:0]      reg_clk200_time;
    logic               reg_clk200_led;
    always_ff @(posedge sys_clk200) begin
        if ( sys_reset ) begin
            reg_clk200_time <= 0;
            reg_clk200_led  <= 0;
        end
        else begin
            reg_clk200_time <= reg_clk200_time + 1;
            if ( reg_clk200_time == 200000000-1 ) begin
                reg_clk200_time <= 0;
                reg_clk200_led  <= ~reg_clk200_led;
            end
        end
    end
    
    logic   [31:0]      reg_clk250_time;
    logic               reg_clk250_led;
    always_ff @(posedge sys_clk250) begin
        if ( sys_reset ) begin
            reg_clk250_time <= 0;
            reg_clk250_led  <= 0;
        end
        else begin
            reg_clk250_time <= reg_clk250_time + 1;
            if ( reg_clk250_time == 250000000-1 ) begin
                reg_clk250_time <= 0;
                reg_clk250_led  <= ~reg_clk250_led;
            end
        end
    end
    
    logic   [7:0]   reg_frame_count;
    always_ff @(posedge axi4s_cam_aclk) begin
        if ( axi4s_csi2_tuser && axi4s_csi2_tvalid ) begin
            reg_frame_count <= reg_frame_count + 1;
        end
    end

    // pmod
    assign pmod[0] = i2c0_scl_o;
    assign pmod[1] = i2c0_scl_t;
    assign pmod[2] = i2c0_sda_o;
    assign pmod[3] = i2c0_sda_t;
    assign pmod[4] = cam_enable;
    assign pmod[5] = reg_frame_count[7];
    assign pmod[6] = reg_clk200_led;
    assign pmod[7] = reg_clk250_led;
    
    
endmodule


`default_nettype wire

