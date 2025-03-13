
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    
    #10000000
        $finish;
    end
    

    // -----------------------------
    //  reset & clock
    // -----------------------------

    localparam RATE100 = 1000.0/100.00;
    localparam RATE200 = 1000.0/200.00;
    localparam RATE250 = 1000.0/250.00;
    localparam RATE133 = 1000.0/133.33;

    logic       reset = 1;
    initial #100 reset = 0;

    logic       clk100 = 1'b1;
    always #(RATE100/2.0) clk100 <= ~clk100;

    logic       clk200 = 1'b1;
    always #(RATE200/2.0) clk200 <= ~clk200;

    logic       clk250 = 1'b1;
    always #(RATE250/2.0) clk250 <= ~clk250;


    // -----------------------------
    //  target
    // -----------------------------

    logic   [0:0]   axi4l_peri_aresetn  ;
    logic           axi4l_peri_aclk     ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (40                     ),
                .DATA_BITS  (64                     )
            )
        axi4l_peri
            (
                .aresetn    (axi4l_peri_aresetn     ),
                .aclk       (axi4l_peri_aclk        ),
                .aclken     (1'b1                   )
            );

    logic   [31:0]  sim_img_width   ;
    logic   [31:0]  sim_img_height  ;

    tb_main
        u_tb_main
            (
                .reset                  (reset              ),
                .clk100                 (clk100             ),
                .clk200                 (clk200             ),
                .clk250                 (clk250             ),
                
                .s_axi4l_peri_aresetn   (axi4l_peri_aresetn ),
                .s_axi4l_peri_aclk      (axi4l_peri_aclk    ),
                .s_axi4l_peri_awaddr    (axi4l_peri.awaddr  ),
                .s_axi4l_peri_awprot    (axi4l_peri.awprot  ),
                .s_axi4l_peri_awvalid   (axi4l_peri.awvalid ),
                .s_axi4l_peri_awready   (axi4l_peri.awready ),
                .s_axi4l_peri_wdata     (axi4l_peri.wdata   ),
                .s_axi4l_peri_wstrb     (axi4l_peri.wstrb   ),
                .s_axi4l_peri_wvalid    (axi4l_peri.wvalid  ),
                .s_axi4l_peri_wready    (axi4l_peri.wready  ),
                .s_axi4l_peri_bresp     (axi4l_peri.bresp   ),
                .s_axi4l_peri_bvalid    (axi4l_peri.bvalid  ),
                .s_axi4l_peri_bready    (axi4l_peri.bready  ),
                .s_axi4l_peri_araddr    (axi4l_peri.araddr  ),
                .s_axi4l_peri_arprot    (axi4l_peri.arprot  ),
                .s_axi4l_peri_arvalid   (axi4l_peri.arvalid ),
                .s_axi4l_peri_arready   (axi4l_peri.arready ),
                .s_axi4l_peri_rdata     (axi4l_peri.rdata   ),
                .s_axi4l_peri_rresp     (axi4l_peri.rresp   ),
                .s_axi4l_peri_rvalid    (axi4l_peri.rvalid  ),
                .s_axi4l_peri_rready    (axi4l_peri.rready  ),
                .img_width              (sim_img_width      ),
                .img_height             (sim_img_height     )
            );



    // -----------------------------
    //  access
    // -----------------------------

`include "jelly/JellyRegs.vh"
    
    localparam type axi4l_addr_t = logic [axi4l_peri.ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [axi4l_peri.DATA_BITS-1:0];

    localparam  axi4l_addr_t    ADR_GPIO   = axi4l_addr_t'(40'ha000_0000);
    localparam  axi4l_addr_t    ADR_FMTR   = axi4l_addr_t'(40'ha010_0000);
    localparam  axi4l_addr_t    ADR_WDMA   = axi4l_addr_t'(40'ha021_0000);
//    localparam  axi4l_addr_t    ADR_WB     = axi4l_addr_t'(40'ha012_1000);
//    localparam  axi4l_addr_t    ADR_DEMOS  = axi4l_addr_t'(40'ha012_2000);
//    localparam  axi4l_addr_t    ADR_COLMAT = axi4l_addr_t'(40'ha012_4000);
    localparam  axi4l_addr_t    ADR_IMGSEL = axi4l_addr_t'(40'ha012_f000);

    jelly3_axi4l_accessor
            #(
                .RAND_RATE_AW   (0),
                .RAND_RATE_W    (0),
                .RAND_RATE_B    (0),
                .RAND_RATE_AR   (0),
                .RAND_RATE_R    (0)
            )
        u_axi4l
            (
                .m_axi4l        (axi4l_peri.m)
            );

    int bayer_phase = 0;

    /* verilator lint_off WIDTHEXPAND */
    initial begin
        axi4l_data_t    rdata;
        
        #(RATE100*200);
        $display("start");
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CORE_ID,          rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CORE_VERSION,     rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_CONTROL,      rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_STATUS,       rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_INDEX,        rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_SKIP,         rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,  rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_WIDTH,      rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_HEIGHT,     rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_FILL,       rdata);
        u_axi4l.read_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_TIMEOUT,    rdata);

        /*
        $display("BlackLevel");
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_PHASE  , axi4l_data_t'(bayer_phase), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET0, axi4l_data_t'(         66), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET1, axi4l_data_t'(         66), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET2, axi4l_data_t'(         66), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET3, axi4l_data_t'(         66), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF0 , axi4l_data_t'(       4620), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF1 , axi4l_data_t'(       4096), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF2 , axi4l_data_t'(       4096), 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF3 , axi4l_data_t'(      10428), 8'hff);
        */

//        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF3 , axi4l_data_t'(       4620), 8'hff);
//        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF2 , axi4l_data_t'(       4096), 8'hff);
//        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF1 , axi4l_data_t'(      10428), 8'hff);
//        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF0 , axi4l_data_t'(       4096), 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF0 , axi4l_data_t'(       4096), 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF1 , axi4l_data_t'(       4096), 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF2 , axi4l_data_t'(       4096), 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF3 , axi4l_data_t'(       4096), 8'hff);
//        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_CTL_CONTROL  , axi4l_data_t'(          3), 8'hff);

//        $display("demos");
//        u_axi4l.write_reg(ADR_DEMOS, `REG_IMG_DEMOSAIC_PARAM_PHASE, axi4l_data_t'(bayer_phase), 8'hff);
//        u_axi4l.write_reg(ADR_DEMOS, `REG_IMG_DEMOSAIC_CTL_CONTROL, axi4l_data_t'(          3), 8'hff);

        $display("imgsel");
        u_axi4l.write_reg(ADR_IMGSEL, `REG_IMG_SELECTOR_CTL_SELECT, axi4l_data_t'(1), 8'hff);


        #(RATE100*100);
        $display("enable");
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_WIDTH     , axi4l_data_t'(sim_img_width ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_HEIGHT    , axi4l_data_t'(sim_img_height), 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_TIMEOUT   , axi4l_data_t'(1000          ), 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT , axi4l_data_t'(100000        ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, axi4l_data_t'(1             ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_CONTROL     , axi4l_data_t'(1             ), 8'hff);
        u_axi4l.read_reg (ADR_FMTR, `REG_VIDEO_FMTREG_CTL_STATUS      , rdata);

        $display("set write DMA");
        u_axi4l.read_reg (ADR_WDMA, `REG_VDMA_WRITE_CORE_ID         , rdata);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_ADDR      , axi4l_data_t'(64'h0000a00                   ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_LINE_STEP , axi4l_data_t'(sim_img_width*4               ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_H_SIZE    , axi4l_data_t'(sim_img_width-1               ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_V_SIZE    , axi4l_data_t'(sim_img_height-1              ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_FRAME_STEP, axi4l_data_t'(sim_img_height*sim_img_width*4), 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_F_SIZE    , axi4l_data_t'(1-1                           ), 8'hff);

        
        $display("start");
        u_axi4l.write_reg(ADR_WDMA, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 3                             , 8'hff);  // update & enable
        
       
        #10000000
        $display("stop");
        u_axi4l.write_reg(ADR_WDMA, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 0                             , 8'hff);  // update & enable
        #1000

        $finish();
    end

endmodule


`default_nettype wire


// end of file
