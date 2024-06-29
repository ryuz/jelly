
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

    parameter   int     WIDTH_BITS  = 16;
    parameter   int     HEIGHT_BITS = 16;
    parameter   int     IMG_WIDTH   = 3280 / 2;
    parameter   int     IMG_HEIGHT  = 2464 / 2;

    kv260_imx219
            #(
                .WIDTH_BITS     (WIDTH_BITS     ),
                .HEIGHT_BITS    (HEIGHT_BITS    ),
                .IMG_WIDTH      (IMG_WIDTH      ),
                .IMG_HEIGHT     (IMG_HEIGHT     )
            )
        u_top
            (
                .cam_clk_p      (),
                .cam_clk_n      (),
                .cam_data_p     (),
                .cam_data_n     (),
                .cam_scl        (),
                .cam_sda        (),
                .cam_enable     (),
                .fan_en         (),
                .pmod           ()
            );
    

    // -----------------------------
    //  Clock & Reset
    // -----------------------------
    
    always_comb force u_top.u_design_1.reset  = reset;
    always_comb force u_top.u_design_1.clk100 = clk100;
    always_comb force u_top.u_design_1.clk200 = clk200;
    always_comb force u_top.u_design_1.clk250 = clk250;

//    always_comb force u_top.u_design_1.m_axi4l_peri_aresetn = ~reset;
//    always_comb force u_top.u_design_1.m_axi4l_peri_aclk    = clk250;

//    always_comb force u_top.u_design_1.s_axi4_mem_aresetn = ~reset;
//    always_comb force u_top.u_design_1.s_axi4_mem_aclk    = clk250;
    

    // -----------------------------
    //  Video input
    // -----------------------------

    localparam DATA_WIDTH      = 10;

//    localparam FILE_NAME       = "../../../../../../data/images/windowswallpaper/Penguins_640x480_bayer10.pgm";
//    localparam FILE_IMG_WIDTH  = 640;
//    localparam FILE_IMG_HEIGHT = 480;
    localparam FILE_NAME       = "../../imx219_820x616_raw10.pgm";
    localparam FILE_IMG_WIDTH  = 820;
    localparam FILE_IMG_HEIGHT = 616;

    localparam SIM_IMG_WIDTH  = 640/2;//128;//256;
    localparam SIM_IMG_HEIGHT = 480/2;//64; //256;


    logic   axi4s_src_aresetn;
    logic   axi4s_src_aclk;

    jelly3_axi4s_if
            #(
                .USER_BITS      (1          ),
                .DATA_BITS      (DATA_WIDTH )
            )
        i_axi4s_src
            (
                .aresetn        (axi4s_src_aresetn),
                .aclk           (axi4s_src_aclk)
            );

    assign axi4s_src_aresetn = u_top.u_mipi_csi2_rx.m_axi4s_aresetn;
    assign axi4s_src_aclk    = u_top.u_mipi_csi2_rx.m_axi4s_aclk;
    
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tuser  = i_axi4s_src.tuser ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tlast  = i_axi4s_src.tlast ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tdata  = i_axi4s_src.tdata ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tvalid = i_axi4s_src.tvalid;
    assign i_axi4s_src.tready = u_top.u_mipi_csi2_rx.axi4s_tready;

    // master
    jelly3_model_axi4s_m
            #(
                .COMPONENTS         (1              ),
                .DATA_BITS          (DATA_WIDTH     ),
                .IMG_WIDTH          (SIM_IMG_WIDTH  ),
                .IMG_HEIGHT         (SIM_IMG_HEIGHT ),
                .H_BLANK            (64             ),
                .V_BLANK            (32             ),
                .FILE_NAME          (FILE_NAME      ),
                .FILE_IMG_WIDTH     (FILE_IMG_WIDTH ),
                .FILE_IMG_HEIGHT    (FILE_IMG_HEIGHT),
                .BUSY_RATE          (0              ),
                .RANDOM_SEED        (0              )
            )
        u_model_axi4s_m
            (
                .aclken             (1'b1           ),
                .enable             (1'b1           ),
                .busy               (               ),

                .m_axi4s            (i_axi4s_src.m  ),
                .out_x              (               ),
                .out_y              (               ),
                .out_f              (               )
            );


    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1  ),
                .DATA_WIDTH         (10 ),
                .INIT_FRAME_NUM     (0  ),
                .X_WIDTH            (32 ),
                .Y_WIDTH            (32 ),
                .F_WIDTH            (32 ),
                .FORMAT             ("P2"   ),
                .FILE_NAME          ("output/csi2_"    ),
                .FILE_EXT           (".pgm" ),
                .SEQUENTIAL_FILE    (1  ),
                .ENDIAN             (0  ),
                .BUSY_RATE          (0  ),
                .RANDOM_SEED        (0  )
            )
        u_axi4s_slave_model_csi2
            (
                .aresetn            (u_top.axi4s_csi2.aresetn    ),
                .aclk               (u_top.axi4s_csi2.aclk       ),
                .aclken             (1'b1                        ), 

                .param_width        (SIM_IMG_WIDTH  ),
                .param_height       (SIM_IMG_HEIGHT ),
                .frame_num          (),

                .s_axi4s_tuser      (u_top.axi4s_csi2.tuser         ),
                .s_axi4s_tlast      (u_top.axi4s_csi2.tlast         ),
                .s_axi4s_tdata      (10'(u_top.axi4s_csi2.tdata)         ),
                .s_axi4s_tvalid     (u_top.axi4s_csi2.tvalid & u_top.axi4s_csi2.tready),
                .s_axi4s_tready     ()
            );
    
    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3  ),
                .DATA_WIDTH         (8  ),
                .INIT_FRAME_NUM     (0  ),
                .X_WIDTH            (32 ),
                .Y_WIDTH            (32 ),
                .F_WIDTH            (32 ),
                .FORMAT             ("P3"   ),
                .FILE_NAME          ("output/wdma_"    ),
                .FILE_EXT           (".ppm" ),
                .SEQUENTIAL_FILE    (1  ),
                .ENDIAN             (0  ),
                .BUSY_RATE          (0  ),
                .RANDOM_SEED        (0  )
            )
        u_axi4s_slave_model_wdma
            (
                .aresetn            (u_top.axi4s_wdma.aresetn    ),
                .aclk               (u_top.axi4s_wdma.aclk       ),
                .aclken             (1'b1                       ), 

                .param_width        (SIM_IMG_WIDTH  ),
                .param_height       (SIM_IMG_HEIGHT ),
                .frame_num          (),

                .s_axi4s_tuser      (u_top.axi4s_wdma.tuser         ),
                .s_axi4s_tlast      (u_top.axi4s_wdma.tlast         ),
                .s_axi4s_tdata      (24'(u_top.axi4s_wdma.tdata)         ),
                .s_axi4s_tvalid     (u_top.axi4s_wdma.tvalid & u_top.axi4s_wdma.tready),
                .s_axi4s_tready     ()
            );
    
    // -----------------------------
    //  Peripheral Bus
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

    /*
    logic   [39:0]  axi4l_peri_araddr   ;
    logic   [2:0]   axi4l_peri_arprot   ;
    logic           axi4l_peri_arready  ;
    logic           axi4l_peri_arvalid  ;
    logic   [39:0]  axi4l_peri_awaddr   ;
    logic   [2:0]   axi4l_peri_awprot   ;
    logic           axi4l_peri_awready  ;
    logic           axi4l_peri_awvalid  ;
    logic           axi4l_peri_bready   ;
    logic   [1:0]   axi4l_peri_bresp    ;
    logic           axi4l_peri_bvalid   ;
    logic   [63:0]  axi4l_peri_rdata    ;
    logic           axi4l_peri_rready   ;
    logic   [1:0]   axi4l_peri_rresp    ;
    logic           axi4l_peri_rvalid   ;
    logic   [63:0]  axi4l_peri_wdata    ;
    logic           axi4l_peri_wready   ;
    logic   [7:0]   axi4l_peri_wstrb    ;
    logic           axi4l_peri_wvalid   ;
    */

    assign axi4l_peri_aresetn = u_top.u_design_1.axi4l_peri_aresetn ;
    assign axi4l_peri_aclk    = u_top.u_design_1.axi4l_peri_aclk    ;

    assign axi4l_peri.awready = u_top.u_design_1.axi4l_peri_awready ;
    assign axi4l_peri.wready  = u_top.u_design_1.axi4l_peri_wready  ;
    assign axi4l_peri.bresp   = u_top.u_design_1.axi4l_peri_bresp   ;
    assign axi4l_peri.bvalid  = u_top.u_design_1.axi4l_peri_bvalid  ;
    assign axi4l_peri.arready = u_top.u_design_1.axi4l_peri_arready ;
    assign axi4l_peri.rdata   = u_top.u_design_1.axi4l_peri_rdata   ;
    assign axi4l_peri.rresp   = u_top.u_design_1.axi4l_peri_rresp   ;
    assign axi4l_peri.rvalid  = u_top.u_design_1.axi4l_peri_rvalid  ;

    always_comb force u_top.u_design_1.axi4l_peri_awaddr  = axi4l_peri.awaddr ;
    always_comb force u_top.u_design_1.axi4l_peri_awprot  = axi4l_peri.awprot ;
    always_comb force u_top.u_design_1.axi4l_peri_awvalid = axi4l_peri.awvalid;
    always_comb force u_top.u_design_1.axi4l_peri_wdata   = axi4l_peri.wdata  ;
    always_comb force u_top.u_design_1.axi4l_peri_wstrb   = axi4l_peri.wstrb  ;
    always_comb force u_top.u_design_1.axi4l_peri_wvalid  = axi4l_peri.wvalid ;
    always_comb force u_top.u_design_1.axi4l_peri_bready  = axi4l_peri.bready ;
    always_comb force u_top.u_design_1.axi4l_peri_araddr  = axi4l_peri.araddr ;
    always_comb force u_top.u_design_1.axi4l_peri_arprot  = axi4l_peri.arprot ;
    always_comb force u_top.u_design_1.axi4l_peri_arvalid = axi4l_peri.arvalid;
    always_comb force u_top.u_design_1.axi4l_peri_rready  = axi4l_peri.rready ;



    // -----------------------------
    //  access
    // -----------------------------

`include "jelly/JellyRegs.vh"
    
    localparam type axi4l_addr_t = logic [axi4l_peri.ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [axi4l_peri.DATA_BITS-1:0];

    localparam  axi4l_addr_t    ADR_GPIO   = axi4l_addr_t'(40'ha000_0000);
    localparam  axi4l_addr_t    ADR_FMTR   = axi4l_addr_t'(40'ha010_0000);
    localparam  axi4l_addr_t    ADR_WDMA   = axi4l_addr_t'(40'ha021_0000);
    localparam  axi4l_addr_t    ADR_WB     = axi4l_addr_t'(40'ha012_1000);
    localparam  axi4l_addr_t    ADR_DEMOS  = axi4l_addr_t'(40'ha012_2000);
    localparam  axi4l_addr_t    ADR_COLMAT = axi4l_addr_t'(40'ha012_4000);


    /*
    localparam  axi4l_addr_t    ADR_CORE_ID            = axi4l_addr_t'('h00) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CORE_VERSION       = axi4l_addr_t'('h01) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_CONTROL        = axi4l_addr_t'('h04) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_STATUS         = axi4l_addr_t'('h05) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_INDEX          = axi4l_addr_t'('h07) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_SKIP           = axi4l_addr_t'('h08) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_FRM_TIMER_EN   = axi4l_addr_t'('h0a) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_CTL_FRM_TIMEOUT    = axi4l_addr_t'('h0b) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_WIDTH        = axi4l_addr_t'('h10) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_HEIGHT       = axi4l_addr_t'('h11) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_FILL         = axi4l_addr_t'('h12) * (axi4l_peri.DATA_BITS/8);
    localparam  axi4l_addr_t    ADR_PARAM_TIMEOUT      = axi4l_addr_t'('h13) * (axi4l_peri.DATA_BITS/8);
    */

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

    int bayer_phase = 3;

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

        $display("BlackLevel");
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_PHASE  , bayer_phase,  8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET0,    66, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET1,    66, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET2,    66, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_OFFSET3,    66, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF3 ,  4620, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF2 ,  4096, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF1 , 10428, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF0 ,  4096, 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF0 ,  4096, 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF1 ,  4096, 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF2 ,  4096, 8'hff);
    //  u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_PARAM_COEFF3 ,  4096, 8'hff);
        u_axi4l.write_reg(ADR_WB, `REG_IMG_BAYER_WB_CTL_CONTROL  ,     3, 8'hff);

        $display("demos");
        u_axi4l.write_reg(ADR_DEMOS, `REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase,  8'hff);
        u_axi4l.write_reg(ADR_DEMOS, `REG_IMG_DEMOSAIC_CTL_CONTROL, 3,  8'hff);


        #(RATE100*100);
        $display("enable");
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_WIDTH     , SIM_IMG_WIDTH , 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_HEIGHT    , SIM_IMG_HEIGHT, 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_PARAM_TIMEOUT   , 1000          , 8'hff);
//      u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT , 100000        , 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1             , 8'hff);
        u_axi4l.write_reg(ADR_FMTR, `REG_VIDEO_FMTREG_CTL_CONTROL     , 1             , 8'hff);
        u_axi4l.read_reg (ADR_FMTR, `REG_VIDEO_FMTREG_CTL_STATUS      , rdata);

        $display("set write DMA");
        u_axi4l.read_reg (ADR_WDMA, `REG_VDMA_WRITE_CORE_ID         , rdata);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_ADDR      , 64'h0000a00                   , 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_LINE_STEP , SIM_IMG_WIDTH*4               , 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_H_SIZE    , SIM_IMG_WIDTH-1               , 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_V_SIZE    , SIM_IMG_HEIGHT-1              , 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_FRAME_STEP, SIM_IMG_HEIGHT*SIM_IMG_WIDTH*4, 8'hff);
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_PARAM_F_SIZE    , 1-1                           , 8'hff);

        /*
        $display("oneshot");
        u_axi4l.write_reg(ADR_WDMA, `REG_VDMA_WRITE_CTL_CONTROL     , 7                             , 8'hff);  // update & enable
        rdata = 1;
        while ( rdata != 0 ) begin
            #10000
            u_axi4l.read_reg (ADR_WDMA, `REG_VIDEO_FMTREG_CTL_STATUS, rdata);
        end
        #100000

        $display("oneshot");
        u_axi4l.write_reg(ADR_WDMA, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 7                             , 8'hff);  // update & enable
        rdata = 1;
        while ( rdata != 0 ) begin
            #10000
            u_axi4l.read_reg (ADR_WDMA, `REG_VIDEO_FMTREG_CTL_STATUS, rdata);
        end
        #100000
        */
        
        $display("start");
        u_axi4l.write_reg(ADR_WDMA, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 3                             , 8'hff);  // update & enable
        
        /*
        // ストレステスト
        for ( int i = 0; i < 10; i++ ) begin
            #100000
            force u_top.u_design_1.aw_busy = 1'b1;
            #200
            force u_top.u_design_1.aw_busy = 1'b0;

            #30000
            force u_top.u_design_1.w_busy = 1'b1;
            #200
            force u_top.u_design_1.w_busy = 1'b0;
        end
        */
       
        #10000000
        $display("stop");
        u_axi4l.write_reg(ADR_WDMA, int'(`REG_VDMA_WRITE_CTL_CONTROL)     , 0                             , 8'hff);  // update & enable
        #1000

        $finish();
 

        /*
        $display("start");
        u_axi4l.read(ADR_FMTR + ADR_CORE_ID,          rdata);
        u_axi4l.read(ADR_FMTR + ADR_CORE_VERSION,     rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_CONTROL,      rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_STATUS,       rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_INDEX,        rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_SKIP,         rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_FRM_TIMER_EN, rdata);
        u_axi4l.read(ADR_FMTR + ADR_CTL_FRM_TIMEOUT,  rdata);
        u_axi4l.read(ADR_FMTR + ADR_PARAM_WIDTH,      rdata);
        u_axi4l.read(ADR_FMTR + ADR_PARAM_HEIGHT,     rdata);
        u_axi4l.read(ADR_FMTR + ADR_PARAM_FILL,       rdata);
        u_axi4l.read(ADR_FMTR + ADR_PARAM_TIMEOUT,    rdata);
                
        #(RATE100*100);
        $display("enable");
        u_axi4l.write(ADR_FMTR + ADR_PARAM_WIDTH       , SIM_IMG_WIDTH , 4'b1111);
        u_axi4l.write(ADR_FMTR + ADR_PARAM_HEIGHT      , SIM_IMG_HEIGHT, 4'b1111);
//      u_axi4l.write(ADR_FMTR + ADR_PARAM_TIMEOUT     , 1000          , 4'b1111);
//      u_axi4l.write(ADR_FMTR + ADR_CTL_FRM_TIMEOUT   , 100000        , 4'b1111);
        u_axi4l.write(ADR_FMTR + ADR_CTL_FRM_TIMER_EN  , 1             , 4'b1111);
        u_axi4l.write(ADR_FMTR + ADR_CTL_CONTROL       , 1             , 4'b1111);
        u_axi4l.read (ADR_FMTR + ADR_CTL_STATUS        , rdata);

        $display("set DEMOSIC");
//        wb_read (ADR_DEMOS + WB_ADR_WIDTH'(`REG_IMG_DEMOSAIC_CORE_ID    ));
//        wb_write(ADR_DEMOS + WB_ADR_WIDTH'(`REG_IMG_DEMOSAIC_PARAM_PHASE),     0, 8'hff);
//        wb_write(ADR_DEMOS + WB_ADR_WIDTH'(`REG_IMG_DEMOSAIC_CTL_CONTROL), 64'h3, 8'hff);

        $display("set write DMA");
        u_axi4l.read (ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_CORE_ID       ));
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_ADDR    ),              64'h0000a00, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_LINE_STEP),             X_NUM*4, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_H_SIZE),                X_NUM-1, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_V_SIZE),                Y_NUM-1, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_FRAME_STEP),      Y_NUM*X_NUM*4, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_PARAM_F_SIZE),                    1-1, 8'hff);
        u_axi4l.write(ADR_VDMAW + axi4l_addr_t'(`REG_VDMA_WRITE_CTL_CONTROL),                       3, 8'hff);  // update & enable
        */
    end

endmodule


`default_nettype wire


// end of file
