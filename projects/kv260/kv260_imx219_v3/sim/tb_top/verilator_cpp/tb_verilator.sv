
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
            input   logic           s_axi4l_peri_rready   
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

    always_comb force u_top.u_design_1.m_axi4l_peri_aresetn = ~reset;
    always_comb force u_top.u_design_1.m_axi4l_peri_aclk    = clk250;

    always_comb force u_top.u_design_1.s_axi4_mem_aresetn = ~reset;
    always_comb force u_top.u_design_1.s_axi4_mem_aclk    = clk250;
    

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


    localparam  SIM_IMG_WIDTH  = 128;//256;
    localparam  SIM_IMG_HEIGHT = 64; //256;

    // master
    jelly3_model_axi4s_m
            #(
                .IMG_WIDTH          (SIM_IMG_WIDTH),
                .IMG_HEIGHT         (SIM_IMG_HEIGHT),
                .H_BLANK            (64),
                .V_BLANK            (32),
                .FILE_NAME          (),//"../Mandrill_256x256.ppm"),
                .FILE_IMG_WIDTH     (256),
                .FILE_IMG_HEIGHT    (256),
                .BUSY_RATE          (0),
                .RANDOM_SEED        (0)
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
