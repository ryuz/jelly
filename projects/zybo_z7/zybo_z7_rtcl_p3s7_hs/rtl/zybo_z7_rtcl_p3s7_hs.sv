

`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_rtcl_p3s7_hs
        #(
            parameter   int         WIDTH_BITS  = 11                        ,
            parameter   type        width_t     = logic [WIDTH_BITS-1:0]    ,
            parameter   int         HEIGHT_BITS = 10                        ,
            parameter   type        height_t    = logic [HEIGHT_BITS-1:0]   ,
            parameter   width_t     IMG_WIDTH   = 640                       ,
            parameter   height_t    IMG_HEIGHT  = 480                       ,
            parameter               DEBUG       = "true"                    
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
    

    // ----------------------------------------
    //  Zynq block
    // ----------------------------------------

    localparam  int     AXI4L_PERI_ADDR_BITS = 32   ;
    localparam  int     AXI4L_PERI_DATA_BITS = 32   ;
    localparam  int     AXI4_MEM_ID_BITS     = 6    ;
    localparam  int     AXI4_MEM_ADDR_BITS   = 32   ;
    localparam  int     AXI4_MEM_DATA_BITS   = 64   ;

    logic           sys_reset           ;
    logic           sys_clk100          ;
    logic           sys_clk200          ;
    logic           sys_clk250          ;
    
    logic           axi4l_peri_aresetn  ;
    logic           axi4l_peri_aclk     ;
    logic           axi4_mem_aresetn    ;
    logic           axi4_mem_aclk       ;
    
    logic           IIC_0_0_scl_i       ;
    logic           IIC_0_0_scl_o       ;
    logic           IIC_0_0_scl_t       ;
    logic           IIC_0_0_sda_i       ;
    logic           IIC_0_0_sda_o       ;
    logic           IIC_0_0_sda_t       ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (AXI4L_PERI_ADDR_BITS   ),
                .DATA_BITS  (AXI4L_PERI_DATA_BITS   )
            )
        axi4l_peri
            (
                .aresetn    (axi4l_peri_aresetn     ),
                .aclk       (axi4l_peri_aclk        ),
                .aclken     (1'b1                   )
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (AXI4_MEM_ID_BITS       ),
                .ADDR_BITS  (AXI4_MEM_ADDR_BITS     ),
                .DATA_BITS  (AXI4_MEM_DATA_BITS     )
            )
        axi4_mem0
            (
                .aresetn    (axi4_mem_aresetn       ),
                .aclk       (axi4_mem_aclk          ),
                .aclken     (1'b1                   )
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (AXI4_MEM_ID_BITS       ),
                .ADDR_BITS  (AXI4_MEM_ADDR_BITS     ),
                .DATA_BITS  (AXI4_MEM_DATA_BITS     )
            )
        axi4_mem1
            (
                .aresetn    (axi4_mem_aresetn       ),
                .aclk       (axi4_mem_aclk          ),
                .aclken     (1'b1                   )
            );

    design_1
        i_design_1
            (
                .sys_reset              (1'b0               ),
                .sys_clock              (in_clk125          ),
                
                .out_reset              (sys_reset          ),
                .out_clk100             (sys_clk100         ),
                .out_clk200             (sys_clk200         ),
                .out_clk250             (sys_clk250         ),
                
                .m_axi4l_peri_aresetn   (axi4l_peri_aresetn ),
                .m_axi4l_peri_aclk      (axi4l_peri_aclk    ),
                .m_axi4l_peri_awaddr    (axi4l_peri.awaddr  ),
                .m_axi4l_peri_awprot    (axi4l_peri.awprot  ),
                .m_axi4l_peri_awvalid   (axi4l_peri.awvalid ),
                .m_axi4l_peri_awready   (axi4l_peri.awready ),
                .m_axi4l_peri_wstrb     (axi4l_peri.wstrb   ),
                .m_axi4l_peri_wdata     (axi4l_peri.wdata   ),
                .m_axi4l_peri_wvalid    (axi4l_peri.wvalid  ),
                .m_axi4l_peri_wready    (axi4l_peri.wready  ),
                .m_axi4l_peri_bresp     (axi4l_peri.bresp   ),
                .m_axi4l_peri_bvalid    (axi4l_peri.bvalid  ),
                .m_axi4l_peri_bready    (axi4l_peri.bready  ),
                .m_axi4l_peri_araddr    (axi4l_peri.araddr  ),
                .m_axi4l_peri_arprot    (axi4l_peri.arprot  ),
                .m_axi4l_peri_arvalid   (axi4l_peri.arvalid ),
                .m_axi4l_peri_arready   (axi4l_peri.arready ),
                .m_axi4l_peri_rdata     (axi4l_peri.rdata   ),
                .m_axi4l_peri_rresp     (axi4l_peri.rresp   ),
                .m_axi4l_peri_rvalid    (axi4l_peri.rvalid  ),
                .m_axi4l_peri_rready    (axi4l_peri.rready  ),
                
                .s_axi4_mem_aresetn     (axi4_mem_aresetn   ),
                .s_axi4_mem_aclk        (axi4_mem_aclk      ),

                .s_axi4_mem0_awid       (axi4_mem0.awid     ),
                .s_axi4_mem0_awaddr     (axi4_mem0.awaddr   ),
                .s_axi4_mem0_awburst    (axi4_mem0.awburst  ),
                .s_axi4_mem0_awcache    (axi4_mem0.awcache  ),
                .s_axi4_mem0_awlen      (axi4_mem0.awlen    ),
                .s_axi4_mem0_awlock     (axi4_mem0.awlock   ),
                .s_axi4_mem0_awprot     (axi4_mem0.awprot   ),
                .s_axi4_mem0_awqos      (axi4_mem0.awqos    ),
    //          .s_axi4_mem0_awregion   (axi4_mem0.awregion ),
                .s_axi4_mem0_awsize     (axi4_mem0.awsize   ),
                .s_axi4_mem0_awvalid    (axi4_mem0.awvalid  ),
                .s_axi4_mem0_awready    (axi4_mem0.awready  ),
                .s_axi4_mem0_wstrb      (axi4_mem0.wstrb    ),
                .s_axi4_mem0_wdata      (axi4_mem0.wdata    ),
                .s_axi4_mem0_wlast      (axi4_mem0.wlast    ),
                .s_axi4_mem0_wvalid     (axi4_mem0.wvalid   ),
                .s_axi4_mem0_wready     (axi4_mem0.wready   ),
                .s_axi4_mem0_bid        (axi4_mem0.bid      ),
                .s_axi4_mem0_bresp      (axi4_mem0.bresp    ),
                .s_axi4_mem0_bvalid     (axi4_mem0.bvalid   ),
                .s_axi4_mem0_bready     (axi4_mem0.bready   ),
                .s_axi4_mem0_araddr     (axi4_mem0.araddr   ),
                .s_axi4_mem0_arburst    (axi4_mem0.arburst  ),
                .s_axi4_mem0_arcache    (axi4_mem0.arcache  ),
                .s_axi4_mem0_arid       (axi4_mem0.arid     ),
                .s_axi4_mem0_arlen      (axi4_mem0.arlen    ),
                .s_axi4_mem0_arlock     (axi4_mem0.arlock   ),
                .s_axi4_mem0_arprot     (axi4_mem0.arprot   ),
                .s_axi4_mem0_arqos      (axi4_mem0.arqos    ),
    //          .s_axi4_mem0_arregion   (axi4_mem0.arregion ),
                .s_axi4_mem0_arsize     (axi4_mem0.arsize   ),
                .s_axi4_mem0_arvalid    (axi4_mem0.arvalid  ),
                .s_axi4_mem0_arready    (axi4_mem0.arready  ),
                .s_axi4_mem0_rid        (axi4_mem0.rid      ),
                .s_axi4_mem0_rresp      (axi4_mem0.rresp    ),
                .s_axi4_mem0_rdata      (axi4_mem0.rdata    ),
                .s_axi4_mem0_rlast      (axi4_mem0.rlast    ),
                .s_axi4_mem0_rvalid     (axi4_mem0.rvalid   ),
                .s_axi4_mem0_rready     (axi4_mem0.rready   ),

                .s_axi4_mem1_awid       (axi4_mem1.awid     ),
                .s_axi4_mem1_awaddr     (axi4_mem1.awaddr   ),
                .s_axi4_mem1_awburst    (axi4_mem1.awburst  ),
                .s_axi4_mem1_awcache    (axi4_mem1.awcache  ),
                .s_axi4_mem1_awlen      (axi4_mem1.awlen    ),
                .s_axi4_mem1_awlock     (axi4_mem1.awlock   ),
                .s_axi4_mem1_awprot     (axi4_mem1.awprot   ),
                .s_axi4_mem1_awqos      (axi4_mem1.awqos    ),
    //          .s_axi4_mem1_awregion   (axi4_mem1.awregion ),
                .s_axi4_mem1_awsize     (axi4_mem1.awsize   ),
                .s_axi4_mem1_awvalid    (axi4_mem1.awvalid  ),
                .s_axi4_mem1_awready    (axi4_mem1.awready  ),
                .s_axi4_mem1_wstrb      (axi4_mem1.wstrb    ),
                .s_axi4_mem1_wdata      (axi4_mem1.wdata    ),
                .s_axi4_mem1_wlast      (axi4_mem1.wlast    ),
                .s_axi4_mem1_wvalid     (axi4_mem1.wvalid   ),
                .s_axi4_mem1_wready     (axi4_mem1.wready   ),
                .s_axi4_mem1_bid        (axi4_mem1.bid      ),
                .s_axi4_mem1_bresp      (axi4_mem1.bresp    ),
                .s_axi4_mem1_bvalid     (axi4_mem1.bvalid   ),
                .s_axi4_mem1_bready     (axi4_mem1.bready   ),
                .s_axi4_mem1_araddr     (axi4_mem1.araddr   ),
                .s_axi4_mem1_arburst    (axi4_mem1.arburst  ),
                .s_axi4_mem1_arcache    (axi4_mem1.arcache  ),
                .s_axi4_mem1_arid       (axi4_mem1.arid     ),
                .s_axi4_mem1_arlen      (axi4_mem1.arlen    ),
                .s_axi4_mem1_arlock     (axi4_mem1.arlock   ),
                .s_axi4_mem1_arprot     (axi4_mem1.arprot   ),
                .s_axi4_mem1_arqos      (axi4_mem1.arqos    ),
    //          .s_axi4_mem1_arregion   (axi4_mem1.arregion ),
                .s_axi4_mem1_arsize     (axi4_mem1.arsize   ),
                .s_axi4_mem1_arvalid    (axi4_mem1.arvalid  ),
                .s_axi4_mem1_arready    (axi4_mem1.arready  ),
                .s_axi4_mem1_rid        (axi4_mem1.rid      ),
                .s_axi4_mem1_rresp      (axi4_mem1.rresp    ),
                .s_axi4_mem1_rdata      (axi4_mem1.rdata    ),
                .s_axi4_mem1_rlast      (axi4_mem1.rlast    ),
                .s_axi4_mem1_rvalid     (axi4_mem1.rvalid   ),
                .s_axi4_mem1_rready     (axi4_mem1.rready   ),

                .DDR_addr               (DDR_addr           ),
                .DDR_ba                 (DDR_ba             ),
                .DDR_cas_n              (DDR_cas_n          ),
                .DDR_ck_n               (DDR_ck_n           ),
                .DDR_ck_p               (DDR_ck_p           ),
                .DDR_cke                (DDR_cke            ),
                .DDR_cs_n               (DDR_cs_n           ),
                .DDR_dm                 (DDR_dm             ),
                .DDR_dq                 (DDR_dq             ),
                .DDR_dqs_n              (DDR_dqs_n          ),
                .DDR_dqs_p              (DDR_dqs_p          ),
                .DDR_odt                (DDR_odt            ),
                .DDR_ras_n              (DDR_ras_n          ),
                .DDR_reset_n            (DDR_reset_n        ),
                .DDR_we_n               (DDR_we_n           ),
                .FIXED_IO_ddr_vrn       (FIXED_IO_ddr_vrn   ),
                .FIXED_IO_ddr_vrp       (FIXED_IO_ddr_vrp   ),
                .FIXED_IO_mio           (FIXED_IO_mio       ),
                .FIXED_IO_ps_clk        (FIXED_IO_ps_clk    ),
                .FIXED_IO_ps_porb       (FIXED_IO_ps_porb   ),
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb  ),
                
                .IIC_0_0_scl_i          (IIC_0_0_scl_i      ),
                .IIC_0_0_scl_o          (IIC_0_0_scl_o      ),
                .IIC_0_0_scl_t          (IIC_0_0_scl_t      ),
                .IIC_0_0_sda_i          (IIC_0_0_sda_i      ),
                .IIC_0_0_sda_o          (IIC_0_0_sda_o      ),
                .IIC_0_0_sda_t          (IIC_0_0_sda_t      )
            );
    
    IOBUF
        i_IOBUF_cam_scl
            (
                .IO     (cam_scl        ),
                .I      (IIC_0_0_scl_o  ),
                .O      (IIC_0_0_scl_i  ),
                .T      (IIC_0_0_scl_t  )
            );

    IOBUF
        i_iobuf_cam_sda
            (
                .IO     (cam_sda        ),
                .I      (IIC_0_0_sda_o  ),
                .O      (IIC_0_0_sda_i  ),
                .T      (IIC_0_0_sda_t  )
            );
    

    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------

    localparam DEC_SYS      = 0;
    localparam DEC_TGEN     = 1;
    localparam DEC_FMTR     = 2;
    localparam DEC_WDMA_IMG = 3;
    localparam DEC_WDMA_BLK = 4;
    localparam DEC_NUM      = 5;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (AXI4L_PERI_ADDR_BITS),
                .DATA_BITS      (AXI4L_PERI_DATA_BITS)
            )
        axi4l_dec [DEC_NUM]
            (
                .aresetn        (axi4l_peri_aresetn  ),
                .aclk           (axi4l_peri_aclk     ),
                .aclken         (1'b1                )
            );
    
    // address map
    assign {axi4l_dec[DEC_SYS     ].addr_base, axi4l_dec[DEC_SYS     ].addr_high} = {32'h4000_0000, 32'h4000_ffff};
    assign {axi4l_dec[DEC_TGEN    ].addr_base, axi4l_dec[DEC_TGEN    ].addr_high} = {32'h4001_0000, 32'h4001_ffff};
    assign {axi4l_dec[DEC_FMTR    ].addr_base, axi4l_dec[DEC_FMTR    ].addr_high} = {32'h4010_0000, 32'h4010_ffff};
//  assign {axi4l_dec[DEC_RGB     ].addr_base, axi4l_dec[DEC_RGB     ].addr_high} = {32'h4012_0000, 32'h4012_ffff};
    assign {axi4l_dec[DEC_WDMA_IMG].addr_base, axi4l_dec[DEC_WDMA_IMG].addr_high} = {32'h4021_0000, 32'h4021_ffff};
    assign {axi4l_dec[DEC_WDMA_BLK].addr_base, axi4l_dec[DEC_WDMA_BLK].addr_high} = {32'h4022_0000, 32'h4022_ffff};

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (DEC_NUM    ),
                .DEC_ADDR_BITS  (28         )
            )
        u_axi4l_addr_decoder
            (
                .s_axi4l        (axi4l_peri   ),
                .m_axi4l        (axi4l_dec    )
            );

    // ----------------------------------------
    //  System Control
    // ----------------------------------------

    localparam  SYSREG_ID             = 4'h0;
    localparam  SYSREG_SW_RESET       = 4'h1;
    localparam  SYSREG_CAM_ENABLE     = 4'h2;
    localparam  SYSREG_CSI_DATA_TYPE  = 4'h3;
    localparam  SYSREG_DPHY_INIT_DONE = 4'h4;
    localparam  SYSREG_FPS_COUNT      = 4'h6;
    localparam  SYSREG_FRAME_COUNT    = 4'h7;
    localparam  SYSREG_IMG_WIDTH      = 4'h8;
    localparam  SYSREG_IMG_HEIGHT     = 4'h9;
    localparam  SYSREG_BLK_WIDTH      = 4'ha;
    localparam  SYSREG_BLK_HEIGHT     = 4'hb;

    (* MARK_DEBUG=DEBUG *)  logic               reg_sw_reset        ;
    (* MARK_DEBUG=DEBUG *)  logic               reg_cam_enable      ;
    (* MARK_DEBUG=DEBUG *)  logic   [7:0]       reg_csi_data_type   ;
    (* MARK_DEBUG=DEBUG *)  logic               reg_dphy_init_done  ;
                            logic   [31:0]      reg_fps_count       ;
                            logic   [31:0]      reg_frame_count     ;
                            width_t             reg_image_width     ;
                            height_t            reg_image_height    ;
                            width_t             reg_black_width     ;
                            height_t            reg_black_height    ;
    always_ff @(posedge axi4l_dec[DEC_SYS].aclk) begin
        if ( ~axi4l_dec[DEC_SYS].aresetn ) begin
            axi4l_dec[DEC_SYS].bvalid <= 1'b0   ;
            axi4l_dec[DEC_SYS].rdata  <= '0     ;
            axi4l_dec[DEC_SYS].rvalid <= 1'b0   ;

            reg_sw_reset      <= 1'b0       ;
            reg_cam_enable    <= 1'b0       ;
            reg_csi_data_type <= 8'h2b      ;
            reg_image_width   <= IMG_WIDTH  ;
            reg_image_height  <= IMG_HEIGHT ;
            reg_black_width   <= 1280       ;
            reg_black_height  <=    1       ;
        end
        else begin
            // write
            if ( axi4l_dec[DEC_SYS].bready ) begin
                axi4l_dec[DEC_SYS].bvalid <= 1'b0;
            end
            if ( axi4l_dec[DEC_SYS].awvalid && axi4l_dec[DEC_SYS].awready 
                    && axi4l_dec[DEC_SYS].wvalid && axi4l_dec[DEC_SYS].wready
                    && axi4l_dec[DEC_SYS].wstrb[0] ) begin
                case ( axi4l_dec[DEC_SYS].awaddr[5:2] )
                SYSREG_SW_RESET     :   reg_sw_reset      <=         1'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_CAM_ENABLE   :   reg_cam_enable    <=         1'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_CSI_DATA_TYPE:   reg_csi_data_type <=         8'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_IMG_WIDTH    :   reg_image_width   <=   width_t'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_IMG_HEIGHT   :   reg_image_height  <=  height_t'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_BLK_WIDTH    :   reg_black_width   <=   width_t'(axi4l_dec[DEC_SYS].wdata);
                SYSREG_BLK_HEIGHT   :   reg_black_height  <=  height_t'(axi4l_dec[DEC_SYS].wdata);
                default:;
                endcase
                axi4l_dec[DEC_SYS].bvalid <= 1'b1;
            end

            // read
            if ( axi4l_dec[DEC_SYS].rready ) begin
                axi4l_dec[DEC_SYS].rdata  <= '0;
                axi4l_dec[DEC_SYS].rvalid <= 1'b0;
            end
            if ( axi4l_dec[DEC_SYS].arvalid && axi4l_dec[DEC_SYS].arready ) begin
                case ( axi4l_dec[DEC_SYS].araddr[5:2] )
                SYSREG_ID            :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(32'h01234567)      ;
                SYSREG_SW_RESET      :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_sw_reset)      ;
                SYSREG_CAM_ENABLE    :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_cam_enable)    ;
                SYSREG_CSI_DATA_TYPE :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_csi_data_type) ;
                SYSREG_DPHY_INIT_DONE:  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_dphy_init_done);
                SYSREG_FPS_COUNT     :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_fps_count)     ;
                SYSREG_FRAME_COUNT   :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_frame_count)   ;
                SYSREG_IMG_WIDTH     :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_image_width)   ;
                SYSREG_IMG_HEIGHT    :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_image_height)  ;
                SYSREG_BLK_WIDTH     :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_black_width)   ;
                SYSREG_BLK_HEIGHT    :  axi4l_dec[DEC_SYS].rdata  <= axi4l_dec[DEC_SYS].DATA_BITS'(reg_black_height)  ;
                default:    axi4l_dec[DEC_SYS].rdata  <= '0    ;
                endcase
                axi4l_dec[DEC_SYS].rvalid <= 1'b1;
            end
        end
    end
    assign axi4l_dec[DEC_SYS].awready = axi4l_dec[DEC_SYS].wvalid  && !axi4l_dec[DEC_SYS].bvalid;
    assign axi4l_dec[DEC_SYS].wready  = axi4l_dec[DEC_SYS].awvalid && !axi4l_dec[DEC_SYS].bvalid;
    assign axi4l_dec[DEC_SYS].bresp   = '0;
    assign axi4l_dec[DEC_SYS].arready = !axi4l_dec[DEC_SYS].rvalid;
    assign axi4l_dec[DEC_SYS].rresp   = '0;

    assign cam_gpio = reg_cam_enable;


    // ----------------------------------------
    //  Timing Generator
    // ----------------------------------------

    logic   [31:0]       timegen_frames;

    timing_generator
            #(
                .TIMER_BITS             (     32),
                .REGADR_BITS            (      8),
                .INIT_CTL_CONTROL       (  2'b11),
                .INIT_PARAM_PERIOD      ( 100000),  // 1ms  (100MHz)
                .INIT_PARAM_TRIG0_START (      1),
                .INIT_PARAM_TRIG0_END   (  90000),
                .INIT_PARAM_TRIG0_POL   (      0)
            )
        u_timing_generator
            (
                .s_axi4l                (axi4l_dec[DEC_TGEN].s  ),
                .out_trig0              (cam_clk                ),
                .out_frames             (timegen_frames         )
            );


    
    // ----------------------------------------
    //  MIPI D-PHY RX
    // ----------------------------------------
    
                            logic               rxbyteclkhs         ;
    (* mark_debug="true" *) logic               system_rst_out      ;
    (* mark_debug="true" *) logic               init_done           ;
    
                            logic               cl_rxclkactivehs    ;
                            logic               cl_stopstate        ;
                            logic               cl_enable           ;
                            logic               cl_rxulpsclknot     ;
                            logic               cl_ulpsactivenot    ;
    
    (* mark_debug="true" *) logic   [7:0]       dl0_rxdatahs        ;
    (* mark_debug="true" *) logic               dl0_rxvalidhs       ;
    (* mark_debug="true" *) logic               dl0_rxactivehs      ;
    (* mark_debug="true" *) logic               dl0_rxsynchs        ;
                            logic               dl0_forcerxmode     ;
                            logic               dl0_stopstate       ;
                            logic               dl0_enable          ;
                            logic               dl0_ulpsactivenot   ;
                            logic               dl0_rxclkesc        ;
                            logic               dl0_rxlpdtesc       ;
                            logic               dl0_rxulpsesc       ;
                            logic   [3:0]       dl0_rxtriggeresc    ;
                            logic   [7:0]       dl0_rxdataesc       ;
                            logic               dl0_rxvalidesc      ;
                            logic               dl0_errsoths        ;
                            logic               dl0_errsotsynchs    ;
                            logic               dl0_erresc          ;
                            logic               dl0_errsyncesc      ;
                            logic               dl0_errcontrol      ;
    
    (* mark_debug="true" *) logic   [7:0]       dl1_rxdatahs        ;
    (* mark_debug="true" *) logic               dl1_rxvalidhs       ;
    (* mark_debug="true" *) logic               dl1_rxactivehs      ;
    (* mark_debug="true" *) logic               dl1_rxsynchs        ;
                            logic               dl1_forcerxmode     ;
                            logic               dl1_stopstate       ;
                            logic               dl1_enable          ;
                            logic               dl1_ulpsactivenot   ;
                            logic               dl1_rxclkesc        ;
                            logic               dl1_rxlpdtesc       ;
                            logic               dl1_rxulpsesc       ;
                            logic   [3:0]       dl1_rxtriggeresc    ;
                            logic   [7:0]       dl1_rxdataesc       ;
                            logic               dl1_rxvalidesc      ;
                            logic               dl1_errsoths        ;
                            logic               dl1_errsotsynchs    ;
                            logic               dl1_erresc          ;
                            logic               dl1_errsyncesc      ;
                            logic               dl1_errcontrol      ;
    
    mipi_dphy_cam
        i_mipi_dphy_cam
            (
                .core_clk           (sys_clk200         ),
                .core_rst           (sys_reset | reg_sw_reset),
                .rxbyteclkhs        (rxbyteclkhs        ),
                .system_rst_out     (system_rst_out     ),
                .init_done          (init_done          ),
                
                .cl_rxclkactivehs   (cl_rxclkactivehs   ),
                .cl_stopstate       (cl_stopstate       ),
                .cl_enable          (cl_enable          ),
                .cl_rxulpsclknot    (cl_rxulpsclknot    ),
                .cl_ulpsactivenot   (cl_ulpsactivenot   ),
                
                .dl0_rxdatahs       (dl0_rxdatahs       ),
                .dl0_rxvalidhs      (dl0_rxvalidhs      ),
                .dl0_rxactivehs     (dl0_rxactivehs     ),
                .dl0_rxsynchs       (dl0_rxsynchs       ),
                
                .dl0_forcerxmode    (dl0_forcerxmode    ),
                .dl0_stopstate      (dl0_stopstate      ),
                .dl0_enable         (dl0_enable         ),
                .dl0_ulpsactivenot  (dl0_ulpsactivenot  ),
                
                .dl0_rxclkesc       (dl0_rxclkesc       ),
                .dl0_rxlpdtesc      (dl0_rxlpdtesc      ),
                .dl0_rxulpsesc      (dl0_rxulpsesc      ),
                .dl0_rxtriggeresc   (dl0_rxtriggeresc   ),
                .dl0_rxdataesc      (dl0_rxdataesc      ),
                .dl0_rxvalidesc     (dl0_rxvalidesc     ),
                
                .dl0_errsoths       (dl0_errsoths       ),
                .dl0_errsotsynchs   (dl0_errsotsynchs   ),
                .dl0_erresc         (dl0_erresc         ),
                .dl0_errsyncesc     (dl0_errsyncesc     ),
                .dl0_errcontrol     (dl0_errcontrol     ),
                
                .dl1_rxdatahs       (dl1_rxdatahs       ),
                .dl1_rxvalidhs      (dl1_rxvalidhs      ),
                .dl1_rxactivehs     (dl1_rxactivehs     ),
                .dl1_rxsynchs       (dl1_rxsynchs       ),
                
                .dl1_forcerxmode    (dl1_forcerxmode    ),
                .dl1_stopstate      (dl1_stopstate      ),
                .dl1_enable         (dl1_enable         ),
                .dl1_ulpsactivenot  (dl1_ulpsactivenot  ),
                
                .dl1_rxclkesc       (dl1_rxclkesc       ),
                .dl1_rxlpdtesc      (dl1_rxlpdtesc      ),
                .dl1_rxulpsesc      (dl1_rxulpsesc      ),
                .dl1_rxtriggeresc   (dl1_rxtriggeresc   ),
                .dl1_rxdataesc      (dl1_rxdataesc      ),
                .dl1_rxvalidesc     (dl1_rxvalidesc     ),
                
                .dl1_errsoths       (dl1_errsoths       ),
                .dl1_errsotsynchs   (dl1_errsotsynchs   ),
                .dl1_erresc         (dl1_erresc         ),
                .dl1_errsyncesc     (dl1_errsyncesc     ),
                .dl1_errcontrol     (dl1_errcontrol     ),
                
                .clk_hs_rxp         (cam_clk_hs_p       ),
                .clk_hs_rxn         (cam_clk_hs_n       ),
                .clk_lp_rxp         (cam_clk_lp_p       ),
                .clk_lp_rxn         (cam_clk_lp_n       ),
                .data_hs_rxp        (cam_data_hs_p      ),
                .data_hs_rxn        (cam_data_hs_n      ),
                .data_lp_rxp        (cam_data_lp_p      ),
                .data_lp_rxn        (cam_data_lp_n      )
           );

    assign cl_enable         = 1'b1;
    assign dl0_forcerxmode   = 1'b0;
    assign dl0_enable        = 1'b1;
    assign dl1_forcerxmode   = 1'b0;
    assign dl1_enable        = 1'b1;
    always_ff @(posedge axi4l_dec[DEC_SYS].aclk) begin
        reg_dphy_init_done <= init_done;
    end


    /*
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
    */

    logic   dphy_clk    ;
    logic   dphy_reset  ;
    assign dphy_clk   = rxbyteclkhs;
    assign dphy_reset = system_rst_out;

    

   // -------------------------------------
    //  RTCL-P3S7 Recv
    // -------------------------------------

    logic   axi4s_cam_aresetn   ;
    logic   axi4s_cam_aclk      ;
    assign axi4s_cam_aresetn = ~sys_reset   ;
//  assign axi4s_cam_aclk    = sys_clk250   ;
    assign axi4s_cam_aclk    = sys_clk200   ;

    jelly3_axi4s_if
            #(
                .USE_LAST       (1'b1               ),
                .USE_USER       (1'b1               ),
                .DATA_BITS      (10                 ),
                .USER_BITS      (1                  ),
                .DEBUG          ("true"             )
            )
        axi4s_blk
            (
                .aresetn        (axi4s_cam_aresetn  ),
                .aclk           (axi4s_cam_aclk     ),
                .aclken         (1'b1               )
            );

    jelly3_axi4s_if
            #(
                .USE_LAST       (1'b1               ),
                .USE_USER       (1'b1               ),
                .DATA_BITS      (10                 ),
                .USER_BITS      (1                  ),
                .DEBUG          ("true"             )
            )
        axi4s_img
            (
                .aresetn        (axi4s_cam_aresetn  ),
                .aclk           (axi4s_cam_aclk     ),
                .aclken         (1'b1               )
            );

    rtcl_p3s7_hs_dphy_recv
            #(
                .X_BITS             ($bits(width_t)     ),
                .Y_BITS             ($bits(height_t)    ),
                .CHANNELS           (1                  ),
                .RAW_BITS           (10                 ),
                .DPHY_LANES         (2                  ),
                .DEBUG              ("false"            )
            )
        u_rtcl_p3s7_hs_dphy_recv
            (
                .param_black_width  (reg_black_width    ),
                .param_black_height (reg_black_height   ),
                .param_image_width  (reg_image_width    ),
                .param_image_height (reg_image_height   ),

                .dphy_reset         (dphy_reset         ),
                .dphy_clk           (dphy_clk           ),
                .dphy_data          ({
                                        dl1_rxdatahs,
                                        dl0_rxdatahs
                                    }),
                .dphy_valid         (dl0_rxvalidhs      ),

                .m_axi4s_black      (axi4s_blk          ),
                .m_axi4s_image      (axi4s_img          )
            );

    jelly3_axi4s_debug_monitor
        u_axi4s_debug_monitor
            (
                .mon_axi4s       (axi4s_img.mon)
            );

    
    // format regularizer
    logic   [WIDTH_BITS-1:0]    fmtr_param_width;
    logic   [HEIGHT_BITS-1:0]   fmtr_param_height;

    jelly3_axi4s_if
            #(
                .DATA_BITS  (10                     ),
                .DEBUG      (DEBUG                  )
            )
        axi4s_fmtr
            (
                .aresetn    (axi4s_cam_aresetn      ),
                .aclk       (axi4s_cam_aclk         ),
                .aclken     (1'b1                   )
            );
    

    // video_format_regularizer
    jelly3_video_format_regularizer
            #(
                .width_t                (logic [WIDTH_BITS-1:0] ),
                .height_t               (logic [HEIGHT_BITS-1:0]),
                .INIT_CTL_CONTROL       (2'b00                  ),
                .INIT_CTL_SKIP          (1                      ),
                .INIT_PARAM_WIDTH       (WIDTH_BITS'(IMG_WIDTH) ),
                .INIT_PARAM_HEIGHT      (HEIGHT_BITS'(IMG_HEIGHT)),
                .INIT_PARAM_FILL        (10'd0                  ),
                .INIT_PARAM_TIMEOUT     (32'h00010000           )
            )
        u_video_format_regularizer
            (
                .s_axi4s                (axi4s_img.s            ),
                .m_axi4s                (axi4s_fmtr.m           ),
                .s_axi4l                (axi4l_dec[DEC_FMTR].s  ),
                .out_param_width        (fmtr_param_width       ),
                .out_param_height       (fmtr_param_height      )
            );
    

    // FIFO
    jelly3_axi4s_if
            #(
                .DATA_BITS  (10               )
            )
        axi4s_fifo
            (
                .aresetn    (axi4s_cam_aresetn),
                .aclk       (axi4s_cam_aclk   ),
                .aclken     (1'b1             )
            );
    
    jelly3_axi4s_fifo
            #(
                .ASYNC          (0          ),
                .PTR_BITS       (9          ),
                .RAM_TYPE       ("block"    ),
                .DOUT_REG       (1          ),
                .S_REG          (1          ),
                .M_REG          (1          )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (axi4s_fmtr.s   ),
                .m_axi4s        (axi4s_fifo.m   ),
                .s_free_size    (               ),
                .m_data_size    (               )
            );

    // DMA write
    jelly3_axi4s_if
            #(
                .DATA_BITS  (16     ),
                .DEBUG      ("true" )
            )
        axi4s_wdma_img
            (
                .aresetn    (axi4s_cam_aresetn),
                .aclk       (axi4s_cam_aclk   ),
                .aclken     (1'b1             )
            );

    assign axi4s_wdma_img.tuser  = axi4s_fifo.tuser ;
    assign axi4s_wdma_img.tlast  = axi4s_fifo.tlast ;
    assign axi4s_wdma_img.tdata  = 16'(axi4s_fifo.tdata) ;
    assign axi4s_wdma_img.tvalid = axi4s_fifo.tvalid;
    assign axi4s_fifo.tready = axi4s_wdma_img.tready;

    jelly3_dma_video_write
            #(
                .AXI4L_ASYNC            (1                      ),
                .AXI4S_ASYNC            (1                      ),
                .ADDR_BITS              (AXI4_MEM_ADDR_BITS     ),
                .INDEX_BITS             (1                      ),
                .SIZE_OFFSET            (1'b1                   ),
                .H_SIZE_BITS            (14                     ),
                .V_SIZE_BITS            (14                     ),
                .F_SIZE_BITS            (14                     ),
                .LINE_STEP_BITS         (16                     ),
                .FRAME_STEP_BITS        (32                     ),
                
                .INIT_CTL_CONTROL       (4'b0000                ),
                .INIT_IRQ_ENABLE        (1'b0                   ),
                .INIT_PARAM_ADDR        (0                      ),
                .INIT_PARAM_AWLEN_MAX   (8'd255                 ),
                .INIT_PARAM_H_SIZE      (14'(IMG_WIDTH-1)       ),
                .INIT_PARAM_V_SIZE      (14'(IMG_HEIGHT-1)      ),
                .INIT_PARAM_LINE_STEP   (16'd8192               ),
                .INIT_PARAM_F_SIZE      (14'd0                  ),
                .INIT_PARAM_FRAME_STEP  (32'(IMG_HEIGHT*8192)   ),
                .INIT_SKIP_EN           (1'b1                   ),
                .INIT_DETECT_FIRST      (3'b010                 ),
                .INIT_DETECT_LAST       (3'b001                 ),
                .INIT_PADDING_EN        (1'b1                   ),
                .INIT_PADDING_DATA      (10'd0                  ),
                
                .BYPASS_GATE            (0                      ),
                .BYPASS_ALIGN           (0                      ),
                .DETECTOR_ENABLE        (1                      ),
                .ALLOW_UNALIGNED        (1                      ), // (0),
                .CAPACITY_BITS          (32                     ),
                
                .WFIFO_PTR_BITS         (9                      ),
                .WFIFO_RAM_TYPE         ("block"                )
            )
        u_dma_video_write_img
            (
                .endian                 (1'b0                   ),

                .s_axi4s                (axi4s_wdma_img.s       ),
                .m_axi4                 (axi4_mem0.mw           ),

                .s_axi4l                (axi4l_dec[DEC_WDMA_IMG].s),
                .out_irq                (                       ),
                
                .buffer_request         (                       ),
                .buffer_release         (                       ),
                .buffer_addr            ('0                     )
            );

    // DMA write black
    jelly3_axi4s_if
            #(
                .DATA_BITS  (16                 ),
                .DEBUG      ("true"             )
            )
        axi4s_wdma_blk
            (
                .aresetn    (axi4s_cam_aresetn  ),
                .aclk       (axi4s_cam_aclk     ),
                .aclken     (1'b1               )
            );


    assign axi4s_wdma_blk.tuser  = axi4s_blk.tuser        ;
    assign axi4s_wdma_blk.tlast  = axi4s_blk.tlast        ;
    assign axi4s_wdma_blk.tdata  = 16'(axi4s_blk.tdata)   ;
    assign axi4s_wdma_blk.tstrb = '1;
    assign axi4s_wdma_blk.tvalid = axi4s_blk.tvalid       ;
    assign axi4s_blk.tready = axi4s_wdma_blk.tready;

    jelly3_dma_video_write
            #(
                .AXI4L_ASYNC            (1                      ),
                .AXI4S_ASYNC            (1                      ),
                .ADDR_BITS              (AXI4_MEM_ADDR_BITS     ),
                .INDEX_BITS             (1                      ),
                .SIZE_OFFSET            (1'b1                   ),
                .H_SIZE_BITS            (14                     ),
                .V_SIZE_BITS            (14                     ),
                .F_SIZE_BITS            (14                     ),
                .LINE_STEP_BITS         (16                     ),
                .FRAME_STEP_BITS        (32                     ),
                
                .INIT_CTL_CONTROL       (4'b0000                ),
                .INIT_IRQ_ENABLE        (1'b0                   ),
                .INIT_PARAM_ADDR        (0                      ),
                .INIT_PARAM_AWLEN_MAX   (8'd255                 ),
                .INIT_PARAM_H_SIZE      (14'(1280-1)            ),
                .INIT_PARAM_V_SIZE      (14'(1-1)               ),
                .INIT_PARAM_LINE_STEP   (16'd8192               ),
                .INIT_PARAM_F_SIZE      (14'd0                  ),
                .INIT_PARAM_FRAME_STEP  (32'(1*8192)            ),
                .INIT_SKIP_EN           (1'b1                   ),
                .INIT_DETECT_FIRST      (3'b010                 ),
                .INIT_DETECT_LAST       (3'b001                 ),
                .INIT_PADDING_EN        (1'b1                   ),
                .INIT_PADDING_DATA      (10'd0                  ),
                
                .BYPASS_GATE            (0                      ),
                .BYPASS_ALIGN           (0                      ),
                .DETECTOR_ENABLE        (1                      ),
                .ALLOW_UNALIGNED        (0                      ),
                .CAPACITY_BITS          (32                     ),
                
                .WFIFO_PTR_BITS         (9                      ),
                .WFIFO_RAM_TYPE         ("block"                )
            )
        u_dma_video_write_blk
            (
                .endian                 (1'b0                   ),

                .s_axi4s                (axi4s_wdma_blk.s       ),
                .m_axi4                 (axi4_mem1.mw           ),

                .s_axi4l                (axi4l_dec[DEC_WDMA_BLK].s),
                .out_irq                (                       ),
                
                .buffer_request         (                       ),
                .buffer_release         (                       ),
                .buffer_addr            ('0                     )
            );


    // read は未使用
    assign axi4_mem1.arid     = 0;
    assign axi4_mem1.araddr   = 0;
    assign axi4_mem1.arburst  = 0;
    assign axi4_mem1.arcache  = 0;
    assign axi4_mem1.arlen    = 0;
    assign axi4_mem1.arlock   = 0;
    assign axi4_mem1.arprot   = 0;
    assign axi4_mem1.arqos    = 0;
    assign axi4_mem1.arregion = 0;
    assign axi4_mem1.arsize   = 0;
    assign axi4_mem1.arvalid  = 0;
    assign axi4_mem1.rready   = 0;
    
        
    
    
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
        if ( axi4s_img.tuser[0] && axi4s_img.tvalid && axi4s_img.tready ) begin
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

