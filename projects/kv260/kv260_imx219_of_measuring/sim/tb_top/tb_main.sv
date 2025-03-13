
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic           reset                   ,
            input   var logic           clk100                  ,
            input   var logic           clk200                  ,
            input   var logic           clk250                  ,
            
            output  var logic           s_axi4l_peri_aresetn    ,
            output  var logic           s_axi4l_peri_aclk       ,
            input   var logic   [39:0]  s_axi4l_peri_awaddr     ,
            input   var logic   [2:0]   s_axi4l_peri_awprot     ,
            input   var logic           s_axi4l_peri_awvalid    ,
            output  var logic           s_axi4l_peri_awready    ,
            input   var logic   [63:0]  s_axi4l_peri_wdata      ,
            input   var logic   [7:0]   s_axi4l_peri_wstrb      ,
            input   var logic           s_axi4l_peri_wvalid     ,
            output  var logic           s_axi4l_peri_wready     ,
            output  var logic   [1:0]   s_axi4l_peri_bresp      ,
            output  var logic           s_axi4l_peri_bvalid     ,
            input   var logic           s_axi4l_peri_bready     ,
            input   var logic   [39:0]  s_axi4l_peri_araddr     ,
            input   var logic   [2:0]   s_axi4l_peri_arprot     ,
            input   var logic           s_axi4l_peri_arvalid    ,
            output  var logic           s_axi4l_peri_arready    ,
            output  var logic   [63:0]  s_axi4l_peri_rdata      ,
            output  var logic   [1:0]   s_axi4l_peri_rresp      ,
            output  var logic           s_axi4l_peri_rvalid     ,
            input   var logic           s_axi4l_peri_rready     ,

            output  var logic   [31:0]  img_width               ,
            output  var logic   [31:0]  img_height              
        );
    

    // -----------------------------
    //  target
    // -----------------------------

    parameter   int     WIDTH_BITS  = 16;
    parameter   int     HEIGHT_BITS = 16;
    parameter   int     IMG_WIDTH   = 3280 / 2;
    parameter   int     IMG_HEIGHT  = 2464 / 2;

    kv260_imx219_of_measuring
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
        axi4s_src
            (
                .aresetn        (axi4s_src_aresetn  ),
                .aclk           (axi4s_src_aclk     ),
                .aclken         (1'b1               )
            );

    assign axi4s_src_aresetn = u_top.u_mipi_csi2_rx.m_axi4s_aresetn;
    assign axi4s_src_aclk    = u_top.u_mipi_csi2_rx.m_axi4s_aclk;
    
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tuser  = axi4s_src.tuser ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tlast  = axi4s_src.tlast ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tdata  = axi4s_src.tdata ;
    always_comb force u_top.u_mipi_csi2_rx.axi4s_tvalid = axi4s_src.tvalid;
    assign axi4s_src.tready = u_top.u_mipi_csi2_rx.axi4s_tready;


    localparam DATA_WIDTH      = 10;
    localparam FILE_NAME       = "../../data/20250215-180912/rec_";
    localparam FILE_EXT        = ".pgm";
    localparam SEQUENTIAL_FILE = 1;
    localparam FILE_IMG_WIDTH  = 640;
    localparam FILE_IMG_HEIGHT = 132;
    localparam SIM_IMG_WIDTH   = 640;
    localparam SIM_IMG_HEIGHT  = 132;
    assign img_width  = SIM_IMG_WIDTH;
    assign img_height = SIM_IMG_HEIGHT;

    // master
    logic  [31:0]  out_x;
    logic  [31:0]  out_y;
    logic  [31:0]  out_f;
    jelly3_model_axi4s_m
            #(
                .COMPONENTS         (1              ),
                .DATA_BITS          (DATA_WIDTH     ),
                .IMG_WIDTH          (SIM_IMG_WIDTH  ),
                .IMG_HEIGHT         (SIM_IMG_HEIGHT ),
                .H_BLANK            (64             ),
                .V_BLANK            (32             ),
                .FILE_NAME          (FILE_NAME      ),
                .FILE_EXT           (FILE_EXT       ),
                .FILE_IMG_WIDTH     (FILE_IMG_WIDTH ),
                .FILE_IMG_HEIGHT    (FILE_IMG_HEIGHT),
                .SEQUENTIAL_FILE    (SEQUENTIAL_FILE),
                .BUSY_RATE          (0              ),
                .RANDOM_SEED        (0              )
            )
        u_model_axi4s_m
            (
                .enable             (1'b1           ),
                .busy               (               ),

                .m_axi4s            (axi4s_src.m    ),
                .out_x              (out_x          ),
                .out_y              (out_y          ),
                .out_f              (out_f          )
            );
    
//  always_comb force axi4s_src.tdata = out_f;

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
    

    /*
    jelly3_mat_if   s_img       ,

    jelly3_model_img_dump
            #(
                .INIT_FRAME_NUM  = 0                     ,
                .F_BITS          = 32                    ,
                .f_t             = logic [F_BITS-1:0]    ,
                .FORMAT          = "P3"                  ,
                .FILE_NAME       = "img_"                ,
                .FILE_EXT        = ".ppm"                ,
                .SEQUENTIAL_FILE = 1                     ,
                .ENDIAN          = 0                     
            )
        (
            jelly3_mat_if.s     s_img       ,

            output  var f_t     frame_num   
        );

    u_top.u_image_processing.u_img_bayer_lk.img_sobel_de;

                .s_mat_rows         (img_sobel_rows     ),
                .s_mat_cols         (img_sobel_cols     ),
                .s_mat_row_first    (img_sobel_row_first),
                .s_mat_row_last     (img_sobel_row_last ),
                .s_mat_col_first    (img_sobel_col_first),
                .s_mat_col_last     (img_sobel_col_last ),
                .s_mat_de           (img_sobel_de       ),
                .s_mat_user         (img_sobel_user     ),
                .s_mat_valid        (img_sobel_valid    ),
    */


    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1  ),
                .DATA_WIDTH         (10 ),
                .INIT_FRAME_NUM     (0  ),
                .X_WIDTH            (32 ),
                .Y_WIDTH            (32 ),
                .F_WIDTH            (32 ),
                .FORMAT             ("P2"   ),
                .FILE_NAME          ("output/wdma_"    ),
                .FILE_EXT           (".pgm" ),
                .SEQUENTIAL_FILE    (1  ),
                .ENDIAN             (1  ), // BGR -> RGB
                .BUSY_RATE          (0  ),
                .RANDOM_SEED        (0  )
            )
        u_axi4s_slave_model_wdma
            (
                .aresetn            (u_top.axi4s_proc.aresetn    ),
                .aclk               (u_top.axi4s_proc.aclk       ),
                .aclken             (u_top.axi4s_proc.aclken     ), 

                .param_width        (SIM_IMG_WIDTH  ),
                .param_height       (SIM_IMG_HEIGHT ),
                .frame_num          (),

                .s_axi4s_tuser      (u_top.axi4s_proc.tuser         ),
                .s_axi4s_tlast      (u_top.axi4s_proc.tlast         ),
                .s_axi4s_tdata      (10'(u_top.axi4s_proc.tdata)         ),
                .s_axi4s_tvalid     (u_top.axi4s_proc.tvalid & u_top.axi4s_proc.tready),
                .s_axi4s_tready     ()
            );
    

    /*
    jelly3_model_axi4s_dump
            #(
                .COMPONENTS         (3                  ),
                .DATA_BITS          (8                  ),
                .INIT_FRAME_NUM     (0                  ),
                .X_BITS             (32                 ),
                .Y_BITS             (32                 ),
                .F_BITS             (32                 ),
                .FORMAT             ("P3"               ),
                .FILE_NAME          ("output/wdma2_"    ),
                .FILE_EXT           (".ppm"             ),
                .SEQUENTIAL_FILE    (1                  ),
                .ENDIAN             (1                  )  // BGR -> RGB
            )
        u_model_axi4s_dump_wdma
            (
                .param_width        (SIM_IMG_WIDTH      ),
                .param_height       (SIM_IMG_HEIGHT     ),
                .frame_num          (),

                .mon_axi4s          (u_top.axi4s_wdma.mon)
            );
    */
    

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
