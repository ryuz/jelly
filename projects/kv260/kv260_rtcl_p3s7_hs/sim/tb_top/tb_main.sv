
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

    parameter   int     WIDTH_BITS  = 16    ;
    parameter   int     HEIGHT_BITS = 16    ;
    parameter   int     IMG_WIDTH   = 640   ;
    parameter   int     IMG_HEIGHT  = 64    ;

    assign img_width  = IMG_WIDTH   ;
    assign img_height = IMG_HEIGHT  ;

    kv260_rtcl_p3s7_hs
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
                .cam_gpio       (),
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


    // -----------------------------
    //  RTCL-P3S7
    // -----------------------------

    tb_rtcl_p3s7_hs
        u_rtcl_p3s7_hs
            ();

    logic               rxreseths   ;
    logic               rxbyteclkhs ;
    logic   [1:0][7:0]  rxdatahs    ;
    logic   [1:0]       rxvalidhs   ;
    logic   [1:0]       rxactivehs  ;
    logic   [1:0]       rxsynchs    ;

    assign rxreseths   = u_rtcl_p3s7_hs.rxreseths  ;
    assign rxbyteclkhs = u_rtcl_p3s7_hs.rxbyteclkhs;
    assign rxdatahs    = u_rtcl_p3s7_hs.rxdatahs   ;
    assign rxvalidhs   = u_rtcl_p3s7_hs.rxvalidhs  ;
    assign rxactivehs  = u_rtcl_p3s7_hs.rxactivehs ;
    assign rxsynchs    = u_rtcl_p3s7_hs.rxsynchs   ;

    initial begin
        force u_top.system_rst_out = rxreseths;
        force u_top.rxbyteclkhs    = rxbyteclkhs;
        force u_top.dl0_rxdatahs   = rxdatahs[0];
        force u_top.dl1_rxdatahs   = rxdatahs[1];
        force u_top.dl0_rxactivehs = rxactivehs[0];
        force u_top.dl1_rxactivehs = rxactivehs[1];
        force u_top.dl0_rxsynchs   = rxsynchs[0];
        force u_top.dl1_rxsynchs   = rxsynchs[1];
        force u_top.dl0_rxvalidhs  = rxactivehs[0] & ~rxsynchs[0];
        force u_top.dl1_rxvalidhs  = rxactivehs[1] & ~rxsynchs[1];
    end

endmodule


`default_nettype wire


// end of file
