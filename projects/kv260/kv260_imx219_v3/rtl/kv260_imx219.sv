


`timescale 1ns / 1ps
`default_nettype none


module kv260_imx219
        #(
            parameter   int     WIDTH_BITS  = 16                ,
            parameter   int     HEIGHT_BITS = 16                ,
            parameter   int     IMG_WIDTH   = 3280 / 2          ,
            parameter   int     IMG_HEIGHT  = 2464 / 2          ,
            parameter           DEVICE      = "ULTRASCALE_PLUS" ,
            parameter           SIMULATION  = "false"           ,
            parameter           DEBUG       = "true"           
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
    //  Zynq UltraScale+ MPSoC block
    // ----------------------------------------

    localparam  int     AXI4L_PERI_ADDR_BITS = 40   ;
    localparam  int     AXI4L_PERI_DATA_BITS = 64   ;
    localparam  int     AXI4_MEM_ID_BITS     = 6    ;
    localparam  int     AXI4_MEM_ADDR_BITS   = 49   ;
    localparam  int     AXI4_MEM_DATA_BITS   = 128  ;
   

    logic       sys_reset           ;
    logic       sys_clk100          ;
    logic       sys_clk200          ;
    logic       sys_clk250          ;

    logic       axi4l_peri_aresetn  ;
    logic       axi4l_peri_aclk     ;
    logic       axi4_mem_aresetn    ;
    logic       axi4_mem_aclk       ;

    (* MARK_DEBUG=DEBUG *)  logic       i2c0_scl_i  ;
    (* MARK_DEBUG=DEBUG *)  logic       i2c0_scl_o  ;
    (* MARK_DEBUG=DEBUG *)  logic       i2c0_scl_t  ;
    (* MARK_DEBUG=DEBUG *)  logic       i2c0_sda_i  ;
    (* MARK_DEBUG=DEBUG *)  logic       i2c0_sda_o  ;
    (* MARK_DEBUG=DEBUG *)  logic       i2c0_sda_t  ;


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
    
    design_1
        u_design_1
            (
                .fan_en                 (fan_en             ),
                
                .out_reset              (sys_reset          ),
                .out_clk100             (sys_clk100         ),
                .out_clk200             (sys_clk200         ),
                .out_clk250             (sys_clk250         ),

                .i2c_scl_i              (i2c0_scl_i         ),
                .i2c_scl_o              (i2c0_scl_o         ),
                .i2c_scl_t              (i2c0_scl_t         ),
                .i2c_sda_i              (i2c0_sda_i         ),
                .i2c_sda_o              (i2c0_sda_o         ),
                .i2c_sda_t              (i2c0_sda_t         ),

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
                .s_axi4_mem0_awuser     (                   ),
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
                .s_axi4_mem0_aruser     (                   ),
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
                .s_axi4_mem0_rready     (axi4_mem0.rready   )
            );
    

    // I2C
    IOBUF
        u_iobuf_i2c0_scl
            (
                .I                      (i2c0_scl_o ),
                .O                      (i2c0_scl_i ),
                .T                      (i2c0_scl_t ),
                .IO                     (cam_scl    )
        );

    IOBUF
        u_iobuf_i2c0_sda
            (
                .I                      (i2c0_sda_o ),
                .O                      (i2c0_sda_i ),
                .T                      (i2c0_sda_t ),
                .IO                     (cam_sda    )
            );

    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------

    localparam DEC_GPIO  = 0;
    localparam DEC_FMTR  = 1;
    localparam DEC_RGB   = 2;
    localparam DEC_WDMA  = 3;

    localparam DEC_NUM   = 4;

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
    assign {axi4l_dec[DEC_GPIO].addr_base, axi4l_dec[DEC_GPIO].addr_high} = {40'ha000_0000, 40'ha000_ffff};
    assign {axi4l_dec[DEC_FMTR].addr_base, axi4l_dec[DEC_FMTR].addr_high} = {40'ha010_0000, 40'ha010_ffff};
    assign {axi4l_dec[DEC_RGB ].addr_base, axi4l_dec[DEC_RGB ].addr_high} = {40'ha012_0000, 40'ha012_ffff};
    assign {axi4l_dec[DEC_WDMA].addr_base, axi4l_dec[DEC_WDMA].addr_high} = {40'ha021_0000, 40'ha021_ffff};

//    assign wb_gid_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h000);   // 0x80000000-0x8000ffff
//    assign wb_fmtr_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h010);   // 0x80100000-0x8010ffff
//    assign wb_rgb_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h012);   // 0x80120000-0x8012ffff
//    assign wb_sel_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h013);   // 0x80130000-0x8013ffff
//    assign wb_vdmaw_stb_i = wb_peri_stb_i & (wb_peri_adr_i[24:13] == 12'h021);   // 0x80210000-0x8021ffff

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
    //  GPIO
    // ----------------------------------------
    
    (* MARK_DEBUG=DEBUG *)  logic           reg_sw_reset;
    (* MARK_DEBUG=DEBUG *)  logic           reg_cam_enable;
    (* MARK_DEBUG=DEBUG *)  logic   [7:0]   reg_csi_data_type;
    (* MARK_DEBUG=DEBUG *)  logic   [2:0]   reg_fmt_select;
    always_ff @(posedge axi4l_dec[DEC_GPIO].aclk) begin
        if ( ~axi4l_dec[DEC_GPIO].aresetn ) begin
            axi4l_dec[DEC_GPIO].bvalid <= 1'b0;
            axi4l_dec[DEC_GPIO].rdata  <= 'x;
            axi4l_dec[DEC_GPIO].rvalid <= 1'b0;

            reg_sw_reset      <= 1'b0;
            reg_cam_enable    <= 1'b0;
            reg_csi_data_type <= 8'h2b;
            reg_fmt_select    <= '0;
        end
        else begin
            // write
            if ( axi4l_dec[DEC_GPIO].bready ) begin
                axi4l_dec[DEC_GPIO].bvalid <= 1'b0;
            end
            if ( axi4l_dec[DEC_GPIO].awvalid && axi4l_dec[DEC_GPIO].awready 
                    && axi4l_dec[DEC_GPIO].wvalid && axi4l_dec[DEC_GPIO].wready
                    && axi4l_dec[DEC_GPIO].wstrb[0] ) begin
                case ( axi4l_dec[DEC_GPIO].awaddr[5:3] )
                1: reg_sw_reset      <= 1'(axi4l_dec[DEC_GPIO].wdata);
                2: reg_cam_enable    <= 1'(axi4l_dec[DEC_GPIO].wdata);
                3: reg_csi_data_type <= 8'(axi4l_dec[DEC_GPIO].wdata);
                4: reg_fmt_select    <= 3'(axi4l_dec[DEC_GPIO].wdata);
                default:;
                endcase
                axi4l_dec[DEC_GPIO].bvalid <= 1'b1;
            end

            // read
            if ( axi4l_dec[DEC_GPIO].rready ) begin
                axi4l_dec[DEC_GPIO].rdata  <= 'x;
                axi4l_dec[DEC_GPIO].rvalid <= 1'b0;
            end
            if ( axi4l_dec[DEC_GPIO].arvalid && axi4l_dec[DEC_GPIO].arready ) begin
                case ( axi4l_dec[DEC_GPIO].awaddr[5:3] )
                0:          axi4l_dec[DEC_GPIO].rdata  <= axi4l_dec[DEC_GPIO].DATA_BITS'(32'h01234567)     ;
                1:          axi4l_dec[DEC_GPIO].rdata  <= axi4l_dec[DEC_GPIO].DATA_BITS'(reg_sw_reset)     ;
                2:          axi4l_dec[DEC_GPIO].rdata  <= axi4l_dec[DEC_GPIO].DATA_BITS'(reg_cam_enable)   ;
                3:          axi4l_dec[DEC_GPIO].rdata  <= axi4l_dec[DEC_GPIO].DATA_BITS'(reg_csi_data_type);
                4:          axi4l_dec[DEC_GPIO].rdata  <= axi4l_dec[DEC_GPIO].DATA_BITS'(reg_fmt_select)   ;
                default:    axi4l_dec[DEC_GPIO].rdata  <= '0    ;
                endcase
                axi4l_dec[DEC_GPIO].rvalid <= 1'b1;
            end
        end
    end
    assign axi4l_dec[DEC_GPIO].awready = axi4l_dec[DEC_GPIO].wvalid  && !axi4l_dec[DEC_GPIO].bvalid;
    assign axi4l_dec[DEC_GPIO].wready  = axi4l_dec[DEC_GPIO].awvalid && !axi4l_dec[DEC_GPIO].bvalid;
    assign axi4l_dec[DEC_GPIO].bresp   = '0;
    assign axi4l_dec[DEC_GPIO].arready = !axi4l_dec[DEC_GPIO].rvalid;
    assign axi4l_dec[DEC_GPIO].rresp   = '0;

    assign cam_enable = reg_cam_enable;


    // ----------------------------------------
    //  MIPI D-PHY RX
    // ----------------------------------------

    logic axi4s_cam_aresetn;
    logic axi4s_cam_aclk   ;
    assign axi4s_cam_aresetn = ~sys_reset;
    assign axi4s_cam_aclk    = sys_clk200;

    jelly3_axi4s_if
            #(
                .DATA_BITS          (10                 ),
                .DEBUG              (DEBUG              )
            )
        axi4s_csi2
            (
                .aresetn            (axi4s_cam_aresetn  ),
                .aclk               (axi4s_cam_aclk     ),
                .aclken             (1'b1               )
            );
    
    imx219_mipi_rx
            #(
                .DEVICE             (DEVICE             ),
                .SIMULATION         (SIMULATION         ),
                .DEBUG              (DEBUG              )
            )
        u_imx219_mipi_rx
            (
                .core_reset         (sys_reset | reg_sw_reset   ),
                .core_clk           (sys_clk200                 ),

                .param_data_type    (reg_csi_data_type  ),
                .cam_clk_p          (cam_clk_p          ),
                .cam_clk_n          (cam_clk_n          ),
                .cam_data_p         (cam_data_p         ),
                .cam_data_n         (cam_data_n         ),
                .m_axi4s            (axi4s_csi2         )
            );
    

    /*
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
    
    (* mark_debug=DEBUG *)  logic   [7:0]       dl0_rxdatahs;
    (* mark_debug=DEBUG *)  logic               dl0_rxvalidhs;
    (* mark_debug=DEBUG *)  logic               dl0_rxactivehs;
    (* mark_debug=DEBUG *)  logic               dl0_rxsynchs;
    
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
    
    (* mark_debug=DEBUG *)  logic   [7:0]       dl1_rxdatahs;
    (* mark_debug=DEBUG *)  logic               dl1_rxvalidhs;
    (* mark_debug=DEBUG *)  logic               dl1_rxactivehs;
    (* mark_debug=DEBUG *)  logic               dl1_rxsynchs;
    
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
        u_mipi_dphy_cam
            (
                .core_clk           (sys_clk200),
                .core_rst           (sys_reset | reg_sw_reset),
                .rxbyteclkhs        (rxbyteclkhs),
                
                .clkoutphy_out      (clkoutphy_out),
                .pll_lock_out       (pll_lock_out),
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
                
                .clk_rxp            (cam_clk_p),
                .clk_rxn            (cam_clk_n),
                .data_rxp           (cam_data_p),
                .data_rxn           (cam_data_n)
           );
    
    wire        dphy_clk   = rxbyteclkhs;
    wire        dphy_reset = system_rst_out;
    

    (* mark_debug=DEBUG *)  logic   [7:0]       dbg_dl0_rxdatahs;
    (* mark_debug=DEBUG *)  logic               dbg_dl0_rxvalidhs;
    (* mark_debug=DEBUG *)  logic               dbg_dl0_rxactivehs;
    (* mark_debug=DEBUG *)  logic               dbg_dl0_rxsynchs;
    (* mark_debug=DEBUG *)  logic   [7:0]       dbg_dl1_rxdatahs;
    (* mark_debug=DEBUG *)  logic               dbg_dl1_rxvalidhs;
    (* mark_debug=DEBUG *)  logic               dbg_dl1_rxactivehs;
    (* mark_debug=DEBUG *)  logic               dbg_dl1_rxsynchs;
    (* mark_debug=DEBUG *)  logic               dbg_valid;
    jelly2_fifo_generic_fwtf
                #(
                    .ASYNC          (1          ),
                    .DATA_WIDTH     (8+3+8+3    ),
                    .PTR_WIDTH      (8          ),
                    .DOUT_REGS      (1          ),
                    .RAM_TYPE       ("block"    ),
                    .LOW_DEALY      (0          ),
                    .S_REGS         (1          ),
                    .M_REGS         (1          )
                )
            u_fifo_generic_fwtf_dbg
                (
                    .s_reset        (dphy_reset ),
                    .s_clk          (dphy_clk   ),
                    .s_cke          (1'b1       ),
                    .s_data         ({
                                        dl0_rxdatahs    ,
                                        dl0_rxvalidhs   ,
                                        dl0_rxactivehs  ,
                                        dl0_rxsynchs    ,
                                        dl1_rxdatahs    ,
                                        dl1_rxvalidhs   ,
                                        dl1_rxactivehs  ,
                                        dl1_rxsynchs    
                                    }),
                    .s_valid        (1'b1       ),
                    .s_ready        (           ),
                    .s_free_count   (           ),

                    .m_reset        (sys_reset  ),
                    .m_clk          (sys_clk200 ),
                    .m_cke          (1'b1       ),
                    .m_data         ({
                                        dbg_dl0_rxdatahs    ,
                                        dbg_dl0_rxvalidhs   ,
                                        dbg_dl0_rxactivehs  ,
                                        dbg_dl0_rxsynchs    ,
                                        dbg_dl1_rxdatahs    ,
                                        dbg_dl1_rxvalidhs   ,
                                        dbg_dl1_rxactivehs  ,
                                        dbg_dl1_rxsynchs    
                                    }),
                    .m_valid        (dbg_valid  ),
                    .m_ready        (1'b1       ),
                    .m_data_count   (           )
                );


    
    // ----------------------------------------
    //  CSI-2
    // ----------------------------------------

    logic axi4s_cam_aresetn;
    logic axi4s_cam_aclk   ;
    assign axi4s_cam_aresetn = ~sys_reset;
    assign axi4s_cam_aclk    = sys_clk200;

    jelly3_axi4s_if
            #(
                .DATA_BITS  (10     ),
                .DEBUG      (DEBUG  )
            )
        axi4s_csi2
            (
                .aresetn    (axi4s_cam_aresetn),
                .aclk       (axi4s_cam_aclk   ),
                .aclken     (1'b1             )
            );
    
    logic           mipi_ecc_corrected;
    logic           mipi_ecc_error;
    logic           mipi_ecc_valid;
    logic           mipi_crc_error;
    logic           mipi_crc_valid;
    logic           mipi_packet_lost;
    logic           mipi_fifo_overflow;
    
    jelly2_mipi_csi2_rx
            #(
                .LANES              (2  ),
                .DATA_WIDTH         (10 ),
                .M_FIFO_ASYNC       (1  ),
                .M_FIFO_PTR_WIDTH   (10 )
            )
        u_mipi_csi2_rx
            (
                .aresetn            (~sys_reset),
                .aclk               (sys_clk250),

                .param_data_type    (reg_csi_data_type),

                .ecc_corrected      (mipi_ecc_corrected),
                .ecc_error          (mipi_ecc_error),
                .ecc_valid          (mipi_ecc_valid),
                .crc_error          (mipi_crc_error),
                .crc_valid          (mipi_crc_valid),
                .packet_lost        (mipi_packet_lost),
                .fifo_overflow      (mipi_fifo_overflow),
                
                .rxreseths          (dphy_reset),
                .rxbyteclkhs        (dphy_clk),
                .rxdatahs           ({dl1_rxdatahs,   dl0_rxdatahs  }),
                .rxvalidhs          ({dl1_rxvalidhs,  dl0_rxvalidhs }),
                .rxactivehs         ({dl1_rxactivehs, dl0_rxactivehs}),
                .rxsynchs           ({dl1_rxsynchs,   dl0_rxsynchs  }),
                
                .m_axi4s_aresetn    (axi4s_cam_aresetn  ),
                .m_axi4s_aclk       (axi4s_cam_aclk     ),
                .m_axi4s_tuser      (axi4s_csi2.tuser   ),
                .m_axi4s_tlast      (axi4s_csi2.tlast   ),
                .m_axi4s_tdata      (axi4s_csi2.tdata   ),
                .m_axi4s_tvalid     (axi4s_csi2.tvalid  ),
                .m_axi4s_tready     (1'b1)  // (axi4s_csi2.tready)
            );
    */
    
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
                .s_axi4s                (axi4s_csi2.s           ),
                .m_axi4s                (axi4s_fmtr.m           ),
                .s_axi4l                (axi4l_dec[DEC_FMTR].s  ),
                .out_param_width        (fmtr_param_width       ),
                .out_param_height       (fmtr_param_height      )
            );
    


    // 現像
   jelly3_axi4s_if
            #(
                .DATA_BITS  (4*10               ),
                .DEBUG      (DEBUG              )
            )
        axi4s_rgb
            (
                .aresetn    (axi4s_cam_aresetn  ),
                .aclk       (axi4s_cam_aclk     ),
                .aclken     (1'b1               )
            );
    
    video_raw_to_rgb
            #(
                .WIDTH_BITS     (WIDTH_BITS         ),
                .HEIGHT_BITS    (HEIGHT_BITS        ),
                .DEVICE         ("RTL"              )
            )
        u_video_raw_to_rgb
            (
                .aclken         (1'b1               ), 
                .in_update_req  (1'b1               ),
                .param_width    (fmtr_param_width   ),
                .param_height   (fmtr_param_height  ),

                .s_axi4s        (axi4s_fmtr.s       ),
                .m_axi4s        (axi4s_rgb.m        ),

                .s_axi4l        (axi4l_dec[DEC_RGB].s)
            );


    /*
    // 現像
    logic   [0:0]               axi4s_rgb_tuser;
    logic                       axi4s_rgb_tlast;
    logic   [39:0]              axi4s_rgb_tdata;
    logic                       axi4s_rgb_tvalid;
    logic                       axi4s_rgb_tready;
    
    logic   [WB_DAT_WIDTH-1:0]  wb_rgb_dat_o;
    logic                       wb_rgb_stb_i;
    logic                       wb_rgb_ack_o;
    
    video_raw_to_rgb
            #(
                
                .TUSER_WIDTH        (1),
                .DATA_WIDTH         (10),
                .X_WIDTH            (X_WIDTH),
                .Y_WIDTH            (Y_WIDTH),
                .WB_ADR_WIDTH       (10),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH)
            )
        u_video_raw_to_rgb
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                
                .in_update_req      (1'b1),

                .param_width        (fmtr_param_width),
                .param_height       (fmtr_param_height),

                .s_axi4s_tuser      (axi4s_fmtr_tuser),
                .s_axi4s_tlast      (axi4s_fmtr_tlast),
                .s_axi4s_tdata      (axi4s_fmtr_tdata),
                .s_axi4s_tvalid     (axi4s_fmtr_tvalid),
                .s_axi4s_tready     (axi4s_fmtr_tready),
                
                .m_axi4s_tuser      (axi4s_rgb_tuser),
                .m_axi4s_tlast      (axi4s_rgb_tlast),
                .m_axi4s_tdata      (axi4s_rgb_tdata),
                .m_axi4s_tvalid     (axi4s_rgb_tvalid),
                .m_axi4s_tready     (axi4s_rgb_tready),

                .s_wb_rst_i         (wb_peri_rst_i),
                .s_wb_clk_i         (wb_peri_clk_i),
                .s_wb_adr_i         (wb_peri_adr_i[9:0]),
                .s_wb_dat_o         (wb_rgb_dat_o),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_we_i          (wb_peri_we_i),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_stb_i         (wb_rgb_stb_i),
                .s_wb_ack_o         (wb_rgb_ack_o)
            );
    

    // 出力切り替え
    logic   [0:0]               axi4s_sel_tuser;
    logic                       axi4s_sel_tlast;
    logic   [31:0]              axi4s_sel_tdata;
    logic                       axi4s_sel_tvalid;
    logic                       axi4s_sel_tready;
    
    logic   [1:0]               reg_sel_fmt;

    logic   [WB_DAT_WIDTH-1:0]  wb_sel_dat_o;
    logic                       wb_sel_stb_i;
    logic                       wb_sel_ack_o;
    always_ff @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_sel_fmt <= '0;
        end
        else begin
            if ( wb_sel_stb_i && wb_peri_we_i ) begin
                reg_sel_fmt <= wb_peri_dat_i[1:0];
            end
        end
    end
    assign wb_sel_dat_o = WB_DAT_WIDTH'(reg_sel_fmt);
    assign wb_sel_ack_o = wb_sel_stb_i;

    assign axi4s_sel_tuser  = axi4s_rgb_tuser ;
    assign axi4s_sel_tlast  = axi4s_rgb_tlast ;
    assign axi4s_sel_tvalid = axi4s_rgb_tvalid;
    assign axi4s_rgb_tready = axi4s_sel_tready;

    always_comb begin
        case ( reg_sel_fmt )
        2'b00: begin // ARGB
                axi4s_sel_tdata = {
                    axi4s_rgb_tdata[39:32],
                    axi4s_rgb_tdata[29:22],
                    axi4s_rgb_tdata[19:12],
                    axi4s_rgb_tdata[ 9: 2]
                };
            end
        2'b01: begin // RGB10bit
                axi4s_sel_tdata = {
                    2'b00,
                    axi4s_rgb_tdata[29:0]
                };
            end
        2'b10: begin // RAW S32
            axi4s_sel_tdata = {
                22'd0,
                axi4s_rgb_tdata[39:30]
            };
        end
        2'b11: begin // RAW S32
            axi4s_sel_tdata = {
                1'b0,
                axi4s_rgb_tdata[39:30],
                axi4s_rgb_tdata[39:30],
                axi4s_rgb_tdata[39:30],
                axi4s_rgb_tdata[39]
            };
        end
        endcase
    end
    */


    // FIFO
    jelly3_axi4s_if
            #(
                .DATA_BITS  (10*4             )
            )
        axi4s_fifo
            (
                .aresetn    (axi4s_cam_aresetn),
                .aclk       (axi4s_cam_aclk   ),
                .aclken     (1'b1             )
            );
    
    jelly3_axi4s_fifo
            #(
                .ASYNC          (0              ),
                .PTR_BITS       (6              ),
                .RAM_TYPE       ("block"        ),
                .DOUT_REG       (1              ),
                .S_REG          (1              ),
                .M_REG          (1              )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (axi4s_rgb.s    ),
                .m_axi4s        (axi4s_fifo.m   ),
                .s_free_size    (               ),
                .m_data_size    (               )
            );

    // DMA write
    jelly3_axi4s_if
            #(
                .DATA_BITS  (32     ),
                .DEBUG      (DEBUG  )
            )
        axi4s_wdma
            (
                .aresetn    (axi4s_cam_aresetn),
                .aclk       (axi4s_cam_aclk   ),
                .aclken     (1'b1             )
            );

    always_comb begin
        axi4s_wdma.tdata = '0;
        case ( reg_fmt_select )
        3'd0: // 8bit BGRx
            begin
                axi4s_wdma.tdata[8*0 +: 8] = axi4s_fifo.tdata[10*0+2 +: 8]; // B
                axi4s_wdma.tdata[8*1 +: 8] = axi4s_fifo.tdata[10*1+2 +: 8]; // G
                axi4s_wdma.tdata[8*2 +: 8] = axi4s_fifo.tdata[10*2+2 +: 8]; // R
                axi4s_wdma.tdata[8*3 +: 8] = axi4s_fifo.tdata[10*3+2 +: 8]; // Raw
            end
        3'd1: // 8bit RGBx
            begin
                axi4s_wdma.tdata[8*0 +: 8] = axi4s_fifo.tdata[10*2+2 +: 8]; // R
                axi4s_wdma.tdata[8*1 +: 8] = axi4s_fifo.tdata[10*1+2 +: 8]; // G
                axi4s_wdma.tdata[8*2 +: 8] = axi4s_fifo.tdata[10*0+2 +: 8]; // B
                axi4s_wdma.tdata[8*3 +: 8] = axi4s_fifo.tdata[10*3+2 +: 8]; // Raw
            end
        3'd2: // 10bit Raw
            begin
                axi4s_wdma.tdata[9:0] = axi4s_fifo.tdata[39:30]; // Raw 10bit
            end
        3'd3: // 16bit Raw
            begin
                axi4s_wdma.tdata[15:0] = {axi4s_fifo.tdata[39:30], axi4s_fifo.tdata[39:34]}; // Raw 16bit
            end
        3'd4: // 32bit B10G10R10
            begin
                axi4s_wdma.tdata[10*0 +: 10] = axi4s_fifo.tdata[10*0 +: 10]; // B
                axi4s_wdma.tdata[10*1 +: 10] = axi4s_fifo.tdata[10*1 +: 10]; // G
                axi4s_wdma.tdata[10*2 +: 10] = axi4s_fifo.tdata[10*2 +: 10]; // R
            end
        3'd5: // 32bit R10G10B10
            begin
                axi4s_wdma.tdata[10*0 +: 10] = axi4s_fifo.tdata[10*2 +: 10]; // R
                axi4s_wdma.tdata[10*1 +: 10] = axi4s_fifo.tdata[10*1 +: 10]; // G
                axi4s_wdma.tdata[10*2 +: 10] = axi4s_fifo.tdata[10*0 +: 10]; // B
            end
        default: ;
        endcase
    end

    assign axi4s_wdma.tuser  = axi4s_fifo.tuser ;
    assign axi4s_wdma.tlast  = axi4s_fifo.tlast ;
//  assign axi4s_wdma.tdata  = 32'(axi4s_fifo.tdata);
//  assign axi4s_wdma.tdata[8*0 +: 8] = axi4s_fifo.tdata[10*0+2 +: 8];
//  assign axi4s_wdma.tdata[8*1 +: 8] = axi4s_fifo.tdata[10*1+2 +: 8];
//  assign axi4s_wdma.tdata[8*2 +: 8] = axi4s_fifo.tdata[10*2+2 +: 8];
//  assign axi4s_wdma.tdata[8*3 +: 8] = axi4s_fifo.tdata[10*3+2 +: 8];
    assign axi4s_wdma.tvalid = axi4s_fifo.tvalid;
    assign axi4s_fifo.tready = axi4s_wdma.tready;

    jelly3_dma_video_write
            #(
                .AXI4L_ASYNC            (1                      ),
                .AXI4S_ASYNC            (1                      ),
                .ADDR_BITS              (AXI4_MEM_ADDR_BITS     ),
                .INDEX_BITS             (1                      ),
                .SIZE_OFFSET            (1'b1                   ),
                .H_SIZE_BITS            (14                     ),
                .V_SIZE_BITS            (14                     ),
                .F_SIZE_BITS            (8                      ),
                .LINE_STEP_BITS         (16                     ),
                .FRAME_STEP_BITS        (32                     ),
                
                .INIT_CTL_CONTROL       (4'b0000                ),
                .INIT_IRQ_ENABLE        (1'b0                   ),
                .INIT_PARAM_ADDR        (0                      ),
                .INIT_PARAM_AWLEN_MAX   (8'd255                 ),
                .INIT_PARAM_H_SIZE      (14'(IMG_WIDTH-1)       ),
                .INIT_PARAM_V_SIZE      (14'(IMG_HEIGHT-1)      ),
                .INIT_PARAM_LINE_STEP   (16'd8192               ),
                .INIT_PARAM_F_SIZE      (8'd0                   ),
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
                
                .WFIFO_PTR_BITS         (8                      ),
                .WFIFO_RAM_TYPE         ("block"                )
            )
        u_dma_video_write
            (
                .endian                 (1'b0                   ),

                .s_axi4s                (axi4s_wdma.s           ),
                .m_axi4                 (axi4_mem0.mw           ),

                .s_axi4l                (axi4l_dec[DEC_WDMA].s  ),
                .out_irq                (                       ),
                
                .buffer_request         (                       ),
                .buffer_release         (                       ),
                .buffer_addr            ('0                     )
            );
    
    // read は未使用
    assign axi4_mem0.arid     = 0;
    assign axi4_mem0.araddr   = 0;
    assign axi4_mem0.arburst  = 0;
    assign axi4_mem0.arcache  = 0;
    assign axi4_mem0.arlen    = 0;
    assign axi4_mem0.arlock   = 0;
    assign axi4_mem0.arprot   = 0;
    assign axi4_mem0.arqos    = 0;
    assign axi4_mem0.arregion = 0;
    assign axi4_mem0.arsize   = 0;
    assign axi4_mem0.arvalid  = 0;
    assign axi4_mem0.rready   = 0;
    
    
    
    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
//  logic   [31:0]      reg_counter_rxbyteclkhs;
//  always_ff @(posedge rxbyteclkhs)   reg_counter_rxbyteclkhs <= reg_counter_rxbyteclkhs + 1;
    
    logic   [31:0]      reg_counter_clk100;
    always_ff @(posedge sys_clk100)    reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    logic   [31:0]      reg_counter_clk200;
    always_ff @(posedge sys_clk200)    reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    logic   [31:0]      reg_counter_clk250;
    always_ff @(posedge sys_clk250)    reg_counter_clk250 <= reg_counter_clk250 + 1;
    
    logic   frame_toggle = 0;
    always_ff @(posedge axi4s_cam_aclk) begin
        if ( axi4s_csi2.tuser[0] && axi4s_csi2.tvalid && axi4s_csi2.tready ) begin
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
        if ( axi4s_csi2.tuser && axi4s_csi2.tvalid ) begin
            reg_frame_count <= reg_frame_count + 1;
        end
    end
    
    // pmod
 //   assign pmod[0] = reg_counter_rxbyteclkhs[25];
//    assign pmod[1] = reg_counter_clk100     [25];
//    assign pmod[2] = reg_counter_clk200     [25];
//    assign pmod[3] = reg_counter_clk250     [25];
    assign pmod[0] = i2c0_scl_o;
    assign pmod[1] = i2c0_scl_t;
    assign pmod[2] = i2c0_sda_o;
    assign pmod[3] = i2c0_sda_t;
    assign pmod[4] = cam_enable;
    assign pmod[5] = reg_frame_count[7];
    assign pmod[7:6] = reg_counter_clk100[9:8];
    
    
    // Debug
    /*
    (* mark_debug = "true" *)   logic               dbg_reset;
    (* mark_debug = "true" *)   logic   [7:0]       dbg0_rxdatahs;
    (* mark_debug = "true" *)   logic               dbg0_rxvalidhs;
    (* mark_debug = "true" *)   logic               dbg0_rxactivehs;
    (* mark_debug = "true" *)   logic               dbg0_rxsynchs;
    (* mark_debug = "true" *)   logic   [7:0]       dbg1_rxdatahs;
    (* mark_debug = "true" *)   logic               dbg1_rxvalidhs;
    (* mark_debug = "true" *)   logic               dbg1_rxactivehs;
    (* mark_debug = "true" *)   logic               dbg1_rxsynchs;
    always_ff @(posedge dphy_clk) begin
        dbg_reset       <=  sys_reset | reg_sw_reset;
        dbg0_rxdatahs   <= dl0_rxdatahs;
        dbg0_rxvalidhs  <= dl0_rxvalidhs;
        dbg0_rxactivehs <= dl0_rxactivehs;
        dbg0_rxsynchs   <= dl0_rxsynchs;
        dbg1_rxdatahs   <= dl1_rxdatahs;
        dbg1_rxvalidhs  <= dl1_rxvalidhs;
        dbg1_rxactivehs <= dl1_rxactivehs;
        dbg1_rxsynchs   <= dl1_rxsynchs;
    end
    */
        
endmodule


`default_nettype wire

