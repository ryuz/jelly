
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   int     AXI4L_ADDR_BITS  = 32                   ,
            parameter   int     AXI4L_DATA_BITS  = 32                   ,
            parameter   int     AXI4L_STRB_BITS  = AXI4L_DATA_BITS / 8  
        )
        (
            input   var logic                           reset           ,
            input   var logic                           clk             ,

            input   var logic                           s_axi4l_aresetn ,
            input   var logic                           s_axi4l_aclk    ,
            input   var logic   [AXI4L_ADDR_BITS-1:0]   s_axi4l_awaddr  ,
            input   var logic   [2:0]                   s_axi4l_awprot  ,
            input   var logic                           s_axi4l_awvalid ,
            output  var logic                           s_axi4l_awready ,
            input   var logic   [AXI4L_STRB_BITS-1:0]   s_axi4l_wstrb   ,
            input   var logic   [AXI4L_DATA_BITS-1:0]   s_axi4l_wdata   ,
            input   var logic                           s_axi4l_wvalid  ,
            output  var logic                           s_axi4l_wready  ,
            output  var logic   [1:0]                   s_axi4l_bresp   ,
            output  var logic                           s_axi4l_bvalid  ,
            input   var logic                           s_axi4l_bready  ,
            input   var logic   [AXI4L_ADDR_BITS-1:0]   s_axi4l_araddr  ,
            input   var logic   [2:0]                   s_axi4l_arprot  ,
            input   var logic                           s_axi4l_arvalid ,
            output  var logic                           s_axi4l_arready ,
            output  var logic   [AXI4L_DATA_BITS-1:0]   s_axi4l_rdata   ,
            output  var logic   [1:0]                   s_axi4l_rresp   ,
            output  var logic                           s_axi4l_rvalid  ,
            input   var logic                           s_axi4l_rready  
        );

    localparam          FILE_NAME       = "../../../../../data/images/windowswallpaper/Chrysanthemum_320x240_bayer10.pgm";
    localparam  int     FILE_IMG_WIDTH  = 320;
    localparam  int     FILE_IMG_HEIGHT = 240;
    localparam  int     IMG_WIDTH       = 320;
    localparam  int     IMG_HEIGHT      = 240;

    localparam  bit     USE_DE       = 1    ;
    localparam  bit     USE_USER     = 0    ;
    localparam  bit     USE_VALID    = 1    ;
    localparam  int     TAPS         = 4    ;
    localparam  int     DE_BITS      = TAPS ;
    localparam  int     CH_DEPTH     = 1    ;
    localparam  int     CH_BITS      = 10   ;
    localparam  int     ROWS_BITS    = 16   ;
    localparam  int     COLS_BITS    = 16   ;
    localparam  int     USER_BITS    = 1    ;
    localparam  bit     ENDIAN       = 0    ;

    localparam  type    rows_t    = logic [ROWS_BITS-1:0]   ;
    localparam  type    cols_t    = logic [COLS_BITS-1:0]   ;

    logic   cke = 1'b1;

    jelly3_mat_if
            #(
                .USE_DE             (USE_DE     ),
                .USE_USER           (USE_USER   ),
                .USE_VALID          (USE_VALID  ),
                .TAPS               (TAPS       ),
                .DE_BITS            (DE_BITS    ),
                .CH_DEPTH           (1          ),
                .CH_BITS            (CH_BITS    ),
                .USER_BITS          (USER_BITS  )
            )
        mat_src
            (
                .reset   ,
                .clk     ,
                .cke
            );
    
//    assign mat_src.rows = rows_t'(IMG_HEIGHT);
//    assign mat_src.cols = cols_t'(IMG_WIDTH );

    jelly3_mat_if
            #(
                .USE_DE             (USE_DE     ),
                .USE_USER           (USE_USER   ),
                .USE_VALID          (USE_VALID  ),
                .TAPS               (TAPS       ),
                .DE_BITS            (DE_BITS    ),
                .CH_DEPTH           (3          ),
                .CH_BITS            (CH_BITS    ),
                .USER_BITS          (USER_BITS  )
            )
        mat_dst
            (
                .reset   ,
                .clk     ,
                .cke
            );

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (AXI4L_ADDR_BITS),
                .DATA_BITS  (AXI4L_DATA_BITS)
            )
        axi4l
            (
                .aresetn    (s_axi4l_aresetn),
                .aclk       (s_axi4l_aclk   ),
                .aclken     (1'b1           )
            );

    assign axi4l.awaddr  = s_axi4l_awaddr  ;
    assign axi4l.awprot  = s_axi4l_awprot  ;
    assign axi4l.awvalid = s_axi4l_awvalid ;
    assign axi4l.wstrb   = s_axi4l_wstrb   ;
    assign axi4l.wdata   = s_axi4l_wdata   ;
    assign axi4l.wvalid  = s_axi4l_wvalid  ;
    assign axi4l.bready  = s_axi4l_bready  ;
    assign axi4l.araddr  = s_axi4l_araddr  ;
    assign axi4l.arprot  = s_axi4l_arprot  ;
    assign axi4l.arvalid = s_axi4l_arvalid ;
    assign axi4l.rready  = s_axi4l_rready  ;

    assign s_axi4l_awready = axi4l.awready  ;
    assign s_axi4l_wready  = axi4l.wready   ;
    assign s_axi4l_bresp   = axi4l.bresp    ;
    assign s_axi4l_bvalid  = axi4l.bvalid   ;
    assign s_axi4l_arready = axi4l.arready  ;
    assign s_axi4l_rdata   = axi4l.rdata    ;
    assign s_axi4l_rresp   = axi4l.rresp    ;
    assign s_axi4l_rvalid  = axi4l.rvalid   ;


    parameter   int             MAX_COLS         = 4096         ;
    parameter                   RAM_TYPE         = "block"      ;
    parameter   bit             RGB_SWAP         = 1            ;
    parameter   bit     [1:0]   INIT_CTL_CONTROL = 2'b01        ;
    parameter   bit     [1:0]   INIT_PARAM_PHASE = 2'b0         ;

    jelly3_img_demosaic_acpi
            #(
                .CH_BITS            (CH_BITS            ),
                .MAX_COLS           (MAX_COLS           ),
                .RAM_TYPE           (RAM_TYPE           ),
                .RGB_SWAP           (RGB_SWAP           ),
                .INIT_CTL_CONTROL   (INIT_CTL_CONTROL   ),
                .INIT_PARAM_PHASE   (INIT_PARAM_PHASE   )
            )
        u_img_demosaic_acpi
            (
                .in_update_req      (1'b1               ),
                .s_img              (mat_src            ),
                .m_img              (mat_dst            ),
                .s_axi4l            (axi4l              )
            );
    

    // source
    jelly3_model_img_m
            #(
                .IMG_CH_DEPTH       (CH_DEPTH           ),
                .IMG_CH_BITS        (CH_BITS            ),
                .IMG_WIDTH          (IMG_WIDTH          ),
                .IMG_HEIGHT         (IMG_HEIGHT         ),
                .COL_BLANK          (0                  ),   // 基本ゼロ
                .ROW_BLANK          (0                  ),   // 末尾にde落ちラインを追加
                .FILE_NAME          (FILE_NAME          ),
                .FILE_EXT           (""                 ),
                .FILE_IMG_WIDTH     (FILE_IMG_WIDTH     ),
                .FILE_IMG_HEIGHT    (FILE_IMG_HEIGHT    ),
                .SEQUENTIAL_FILE    (0                  ),
                .ENDIAN             (ENDIAN             )
            )
        u_model_img_m
            (
                .enable             (1'b1               ),
                .busy               (                   ),

                .m_img              (mat_src.m          ),
                .out_x              (                   ),
                .out_y              (                   ),
                .out_f              (                   )
            );

    // dump
    jelly3_model_img_dump
            #(
                .FORMAT             ("P3"               ),
                .FILE_NAME          ("img_"             ),
                .FILE_EXT           (".ppm"             ),
                .SEQUENTIAL_FILE    (1                  ),
                .ENDIAN             (ENDIAN             )
            )
        u_model_img_dump
            (
                .s_img              (mat_dst.s          ),
                .frame_num          (                   )
            );


endmodule


`default_nettype wire


// end of file
