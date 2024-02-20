
`timescale 1ns / 1ps
`default_nettype none


module tb_verilator
        (
            input   logic           reset                   ,
            input   logic           clk100                  ,
            input   logic           clk200                  ,
            input   logic           clk250                  ,
            
            output  logic           s_axi4l_peri_aresetn    ,
            output  logic           s_axi4l_peri_aclk       ,
            input   logic   [39:0]  s_axi4l_peri_awaddr     ,
            input   logic   [2:0]   s_axi4l_peri_awprot     ,
            input   logic           s_axi4l_peri_awvalid    ,
            output  logic           s_axi4l_peri_awready    ,
            input   logic   [63:0]  s_axi4l_peri_wdata      ,
            input   logic   [7:0]   s_axi4l_peri_wstrb      ,
            input   logic           s_axi4l_peri_wvalid     ,
            output  logic           s_axi4l_peri_wready     ,
            output  logic   [1:0]   s_axi4l_peri_bresp      ,
            output  logic           s_axi4l_peri_bvalid     ,
            input   logic           s_axi4l_peri_bready     ,
            input   logic   [39:0]  s_axi4l_peri_araddr     ,
            input   logic   [2:0]   s_axi4l_peri_arprot     ,
            input   logic           s_axi4l_peri_arvalid    ,
            output  logic           s_axi4l_peri_arready    ,
            output  logic   [63:0]  s_axi4l_peri_rdata      ,
            output  logic   [1:0]   s_axi4l_peri_rresp      ,
            output  logic           s_axi4l_peri_rvalid     ,
            input   logic           s_axi4l_peri_rready     ,

            output  logic   [31:0]  img_width               ,
            output  logic   [31:0]  img_height              
        );
    

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

    logic   axi4s_src_aresetn;
    logic   axi4s_src_aclk;

    jelly3_axi4s_if
            #(
                .USER_BITS      (1),
                .DATA_BITS      (10)
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


    localparam DATA_WIDTH      = 10;

//    localparam FILE_NAME       = "../../../../../../data/images/windowswallpaper/Penguins_640x480_bayer10.pgm";
//    localparam FILE_IMG_WIDTH  = 640;
//    localparam FILE_IMG_HEIGHT = 480;
    localparam FILE_NAME       = "../../imx219_820x616_raw10.pgm";
    localparam FILE_IMG_WIDTH  = 820;
    localparam FILE_IMG_HEIGHT = 616;

//    localparam SIM_IMG_WIDTH  = 640/2;//128;//256;
//    localparam SIM_IMG_HEIGHT = 480/2;//64; //256;
    localparam SIM_IMG_WIDTH  = 820;//640;//128;//256;
    localparam SIM_IMG_HEIGHT = 616;//480;//64; //256;
    assign img_width  = SIM_IMG_WIDTH;
    assign img_height = SIM_IMG_HEIGHT;

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
    



    jelly2_img_slave_model
            #(
                .COMPONENTS         (1              ),
                .DATA_WIDTH         (11             ),
                .FORMAT             ("P2"           ),
                .FILE_NAME          ("output/wb_"   ),
                .FILE_EXT           (".pgm"         ),
                .SEQUENTIAL_FILE    (1              ),
                .ENDIAN             (0              )
            )
        u_img_slave_model
            (
                .reset              (u_top.u_video_raw_to_rgb.img_wb.reset      ),
                .clk                (u_top.u_video_raw_to_rgb.img_wb.clk        ),
                .cke                (u_top.u_video_raw_to_rgb.img_wb.cke        ),
                .param_width        (SIM_IMG_WIDTH),
                .param_height       (SIM_IMG_HEIGHT),
                .frame_num          (),
                .s_img_row_first    (u_top.u_video_raw_to_rgb.img_wb.row_first  ),
                .s_img_row_last     (u_top.u_video_raw_to_rgb.img_wb.row_last   ),
                .s_img_col_first    (u_top.u_video_raw_to_rgb.img_wb.col_first  ),
                .s_img_col_last     (u_top.u_video_raw_to_rgb.img_wb.col_last   ),
                .s_img_de           (u_top.u_video_raw_to_rgb.img_wb.de         ),
                .s_img_data         (u_top.u_video_raw_to_rgb.img_wb.data       ),
                .s_img_valid        (u_top.u_video_raw_to_rgb.img_wb.valid      )
            );


    // -----------------------------
    //  Peripheral Bus
    // -----------------------------

    assign s_axi4l_peri_aresetn = u_top.u_design_1.axi4l_peri_aresetn ;
    assign s_axi4l_peri_aclk    = u_top.u_design_1.axi4l_peri_aclk    ;

    assign s_axi4l_peri_awready = u_top.u_design_1.axi4l_peri_awready ;
    assign s_axi4l_peri_wready  = u_top.u_design_1.axi4l_peri_wready  ;
    assign s_axi4l_peri_bresp   = u_top.u_design_1.axi4l_peri_bresp   ;
    assign s_axi4l_peri_bvalid  = u_top.u_design_1.axi4l_peri_bvalid  ;
    assign s_axi4l_peri_arready = u_top.u_design_1.axi4l_peri_arready ;
    assign s_axi4l_peri_rdata   = u_top.u_design_1.axi4l_peri_rdata   ;
    assign s_axi4l_peri_rresp   = u_top.u_design_1.axi4l_peri_rresp   ;
    assign s_axi4l_peri_rvalid  = u_top.u_design_1.axi4l_peri_rvalid  ;

    always_comb force u_top.u_design_1.axi4l_peri_awaddr  = s_axi4l_peri_awaddr ;
    always_comb force u_top.u_design_1.axi4l_peri_awprot  = s_axi4l_peri_awprot ;
    always_comb force u_top.u_design_1.axi4l_peri_awvalid = s_axi4l_peri_awvalid;
    always_comb force u_top.u_design_1.axi4l_peri_wdata   = s_axi4l_peri_wdata  ;
    always_comb force u_top.u_design_1.axi4l_peri_wstrb   = s_axi4l_peri_wstrb  ;
    always_comb force u_top.u_design_1.axi4l_peri_wvalid  = s_axi4l_peri_wvalid ;
    always_comb force u_top.u_design_1.axi4l_peri_bready  = s_axi4l_peri_bready ;
    always_comb force u_top.u_design_1.axi4l_peri_araddr  = s_axi4l_peri_araddr ;
    always_comb force u_top.u_design_1.axi4l_peri_arprot  = s_axi4l_peri_arprot ;
    always_comb force u_top.u_design_1.axi4l_peri_arvalid = s_axi4l_peri_arvalid;
    always_comb force u_top.u_design_1.axi4l_peri_rready  = s_axi4l_peri_rready ;


endmodule


`default_nettype wire


// end of file
