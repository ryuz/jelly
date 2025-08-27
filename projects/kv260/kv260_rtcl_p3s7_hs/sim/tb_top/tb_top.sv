
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

    localparam  axi4l_addr_t    ADR_SYS    = axi4l_addr_t'(40'ha000_0000);
    localparam  axi4l_addr_t    ADR_TGEN   = axi4l_addr_t'(40'ha001_0000);
    localparam  axi4l_addr_t    ADR_FMTR   = axi4l_addr_t'(40'ha010_0000);
    localparam  axi4l_addr_t    ADR_WDMA0  = axi4l_addr_t'(40'ha021_0000);
    localparam  axi4l_addr_t    ADR_WDMA1  = axi4l_addr_t'(40'ha022_0000);

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
        u_axi4l.read_reg(ADR_SYS, 0, rdata);
        u_axi4l.read_reg(ADR_SYS, 7, rdata);
        u_axi4l.read_reg(ADR_SYS, 8, rdata);
        u_axi4l.read_reg(ADR_SYS, 9, rdata);
        u_axi4l.read_reg(ADR_SYS,10, rdata);
//      u_axi4l.write_reg(ADR_SYS, 8, 64, 8'hff);
//      u_axi4l.write_reg(ADR_SYS, 9, 32, 8'hff);
        u_axi4l.read_reg(ADR_SYS, 8, rdata);
        u_axi4l.read_reg(ADR_SYS, 9, rdata);

        u_axi4l.read_reg(ADR_TGEN, 0, rdata);

//      #(RATE100*200);
        $display("fmtr");
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_WIDTH     , axi4l_data_t'(sim_img_width ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_HEIGHT    , axi4l_data_t'(sim_img_height), 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_TIMEOUT   , axi4l_data_t'(1000          ), 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT , axi4l_data_t'(100000        ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, axi4l_data_t'(1             ), 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_CONTROL     , axi4l_data_t'(1             ), 8'hff);
        u_axi4l.read_reg (ADR_FMTR, `REG_VIDEO_FMTREG_CTL_STATUS      , rdata);

        #100000
        for ( int i = 0; i < 15; i++ ) begin
            $display("set write DMA1");
            u_axi4l.read_reg (ADR_WDMA1, `REG_VDMA_WRITE_CORE_ID         , rdata);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_ADDR      , axi4l_data_t'(64'h0000000          ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_LINE_STEP , axi4l_data_t'(1280*2               ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_H_SIZE    , axi4l_data_t'(1280-1               ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_V_SIZE    , axi4l_data_t'(1-1                  ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_FRAME_STEP, axi4l_data_t'(1*1280*2             ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_PARAM_F_SIZE    , axi4l_data_t'(1-1                  ), 8'hff);
            u_axi4l.write_reg(ADR_WDMA1, `REG_VDMA_WRITE_CTL_CONTROL     , axi4l_data_t'(7                    ), 8'hff);  // oneshot & update & enable
            do begin
                u_axi4l.read_reg (ADR_WDMA1, `REG_VDMA_WRITE_CTL_STATUS, rdata);
                #10000;
            end while ( rdata != 0);
        #100000;
        end
        #1000
        $finish;

        $display("set write DMA0");
        u_axi4l.read_reg (ADR_WDMA0, `REG_VDMA_WRITE_CORE_ID         , rdata);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_ADDR      , axi4l_data_t'(64'h0000a00                   ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_LINE_STEP , axi4l_data_t'(sim_img_width*2               ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_H_SIZE    , axi4l_data_t'(sim_img_width-1               ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_V_SIZE    , axi4l_data_t'(sim_img_height-1              ), 8'hff);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_FRAME_STEP, axi4l_data_t'(sim_img_height*sim_img_width*4), 8'hff);
        u_axi4l.write_reg(ADR_WDMA0, `REG_VDMA_WRITE_PARAM_F_SIZE    , axi4l_data_t'(1-1                           ), 8'hff);

        
        $display("start");
        u_axi4l.write_reg(ADR_WDMA0, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 3                             , 8'hff);  // update & enable
        
       
        #2000000
        $display("stop");
        u_axi4l.write_reg(ADR_WDMA0, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 0                             , 8'hff);  // update & enable
        #1000



        u_axi4l.read_reg (ADR_WDMA1, `REG_VDMA_WRITE_CTL_STATUS, rdata);
        #1000000
        u_axi4l.read_reg (ADR_WDMA1, `REG_VDMA_WRITE_CTL_STATUS, rdata);
        
        #2000000
        $finish();
    end

endmodule


`default_nettype wire


// end of file
