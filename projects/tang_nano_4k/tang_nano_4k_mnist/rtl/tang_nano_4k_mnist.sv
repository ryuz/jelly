
`default_nettype none

module tang_nano_4k_mnist
        (
            input   var logic           in_reset_n      ,
            input   var logic           in_clk          ,   // 27MHz

            output  var logic   [0:0]   led_n           ,

            inout   tri logic           ov2640_sda      ,
            inout   tri logic           ov2640_scl      ,
            input   var logic           ov2640_vsync    ,
            input   var logic           ov2640_href     ,
            input   var logic   [9:0]   ov2640_pixdata  ,
            input   var logic           ov2640_pixclk   ,
            output  var logic           ov2640_xclk     ,

            output  var logic           tmds_clk_p      ,
            output  var logic           tmds_clk_n      ,
            output  var logic   [2:0]   tmds_data_p     ,
            output  var logic   [2:0]   tmds_data_n     ,

            output  var logic   [0:0]   O_hpram_ck      ,
            output  var logic   [0:0]   O_hpram_ck_n    ,
            output  var logic   [0:0]   O_hpram_cs_n    ,
            output  var logic   [0:0]   O_hpram_reset_n ,
            inout   tri logic   [7:0]   IO_hpram_dq     ,
            inout   tri logic   [0:0]   IO_hpram_rwds   
        );
    
    // -----------------------------
    //  Reset & Clocks
    // -----------------------------

    logic   clk_12      ;
    logic   tmds_clk    ;
    logic   pll_lock    ;
    TMDS_PLLVR
        u_TMDS_PLLVR
            (
                .clkin      (in_clk     ),
                .clkout     (tmds_clk   ),
                .clkoutd    (clk_12     ),
                .lock       (pll_lock   )
            );

    /*
    logic   sys_reset_n;
    Reset_Sync
        u_Reset_Sync
            (
                .resetn     (sys_reset_n            ),
                .ext_reset  (in_reset_n & pll_lock  ),
                .clk        (in_clk                 )
            );
    */

    logic   reset;
    jelly_reset
        u_reset
        (
            .clk        (in_clk                     ),
            .in_reset   (~in_reset_n || ~pll_lock   ),
            .out_reset  (reset                      )
        );

    logic   mem_clk;
    logic   mem_pll_lock;
    GW_PLLVR
        u_GW_PLLVR
            (
                .clkout     (mem_clk        ),
                .lock       (mem_pll_lock   ),
                .clkin      (in_clk         )
            );

    logic   dvi_reset ;
    assign dvi_reset = reset ||  ~pll_lock;

    logic   dvi_pix_clk ;
    CLKDIV
            #(
                .DIV_MODE   ("5"        )
            )
        u_clkdiv
            (
                .RESETN     (~dvi_reset ),
                .HCLKIN     (tmds_clk   ),  // clk  x5
                .CLKOUT     (dvi_pix_clk),  // clk  x1
                .CALIB      (1'b1       )
            );


    /*
    logic   clk_dvi;   //
    logic   clk_12;
    logic   lock;
    PLLVR
            #(
                .FCLKIN             ("27"       ),
                .DYN_IDIV_SEL       ("false"    ),
                .IDIV_SEL           (3          ),
                .DYN_FBDIV_SEL      ("false"    ),
                .FBDIV_SEL          (54         ),
                .DYN_ODIV_SEL       ("false"    ),
                .ODIV_SEL           (2          ),
                .PSDA_SEL           ("0000"     ),
                .DYN_DA_EN          ("false"    ),
                .DUTYDA_SEL         ("1000"     ),
                .CLKOUT_FT_DIR      (1'b1       ),
                .CLKOUTP_FT_DIR     (1'b1       ),
                .CLKOUT_DLY_STEP    (0          ),
                .CLKOUTP_DLY_STEP   (0          ),
                .CLKFB_SEL          ("internal" ),
                .CLKOUT_BYPASS      ("false"    ),
                .CLKOUTP_BYPASS     ("false"    ),
                .CLKOUTD_BYPASS     ("false"    ),
                .DYN_SDIV_SEL       (30         ),
                .CLKOUTD_SRC        ("CLKOUT"   ),
                .CLKOUTD3_SRC       ("CLKOUT"   ),
                .DEVICE             ("GW1NSR-4C")
            )
        u_pllvr
            (
                .CLKOUT             (clk_dvi    ),  // 371.25MHz
                .LOCK               (lock       ),
                .CLKOUTP            (           ),
                .CLKOUTD            (clk_12     ),  // 12.375MHz
                .CLKOUTD3           (           ),
                .RESET              (1'b0       ),
                .RESET_P            (1'b0       ),
                .CLKIN              (clk27      ),
                .CLKFB              ('0         ),
                .FBDSEL             ('0         ),
                .IDSEL              ('0         ),
                .ODSEL              ('0         ),
                .PSDA               ('0         ),
                .DUTYDA             ('0         ),
                .FDLY               ('0         ),
                .VREN               (1'b1       )
            );
    */
    

    // -----------------------------
    //  OV2640
    // -----------------------------

    assign  ov2640_xclk = clk_12;

    OV2640_Controller
        u_OV2640_Controller
            (
                .clk                (clk_12     ),
                .resend             (1'b0       ),
                .config_finished    (           ),
                .sioc               (ov2640_scl ),
                .siod               (ov2640_sda ),
                .reset              (           ),
                .pwdn               (           )
            );



    // -----------------------------
    //  DVI-TX
    // -----------------------------

    logic   syn_re;
    logic   syn_de;
    logic   syn_hs;
    logic   syn_vs;
    syn_gen
        u_syn_gen
            (                                   
                .I_pxl_clk  (dvi_pix_clk    ),//40MHz      //65MHz      //74.25MHz    
                .I_rst_n    (~dvi_reset     ),//800x600    //1024x768   //1280x720       
                .I_h_total  (16'd1650       ),// 16'd1056  // 16'd1344  // 16'd1650    
                .I_h_sync   (16'd40         ),// 16'd128   // 16'd136   // 16'd40     
                .I_h_bporch (16'd220        ),// 16'd88    // 16'd160   // 16'd220     
                .I_h_res    (16'd1280       ),// 16'd800   // 16'd1024  // 16'd1280    
                .I_v_total  (16'd750        ),// 16'd628   // 16'd806   // 16'd750      
                .I_v_sync   (16'd5          ),// 16'd4     // 16'd6     // 16'd5        
                .I_v_bporch (16'd20         ),// 16'd23    // 16'd29    // 16'd20        
                .I_v_res    (16'd720        ),// 16'd600   // 16'd768   // 16'd720      
                .I_rd_hres  (16'd640        ),
                .I_rd_vres  (16'd480        ),
                .I_hs_pol   (1'b1           ),//HS polarity , 0:负极性，1：正极性
                .I_vs_pol   (1'b1           ),//VS polarity , 0:负极性，1：正极性
                .O_rden     (syn_re         ),
                .O_de       (syn_de         ),
                .O_hs       (syn_hs         ),
                .O_vs       (syn_vs         )
            );

    logic   dly0_de, dly1_de;
    logic   dly0_hs, dly1_hs;
    logic   dly0_vs, dly1_vs;
    always_ff @(posedge dvi_pix_clk) begin
        dly0_de <= syn_de;
        dly0_hs <= syn_hs;
        dly0_vs <= syn_vs;
        dly1_de <= dly0_de;
        dly1_hs <= dly0_hs;
        dly1_vs <= dly0_vs;
    end



    logic               buf_de;
    logic   [15:0]      buf_data;
    frame_buffer
        u_frame_buffer
            (
                .reset              ,
                .clk                (in_clk                 ),
                .mem_clk            ,
                .mem_pll_lock       ,

                .vin_clk            (ov2640_pixclk          ),
                .vin_vs_n           (ov2640_vsync           ),
                .vin_de             (ov2640_href            ),
                .vin_data           ({6'd0, ov2640_pixdata} ),
                .vin_fifo_full      (                       ),
                
                .vout_clk           (dvi_pix_clk            ),
                .vout_vs_n          (~syn_vs                ),
                .vout_de            (syn_re                 ),
                .vout_den           (buf_de                 ),
                .vout_data          (buf_data               ),
                .vout_fifo_empty    (                       ),
                
                .O_hpram_ck         ,
                .O_hpram_ck_n       ,
                .O_hpram_cs_n       ,
                .O_hpram_reset_n    ,
                .IO_hpram_dq        ,
                .IO_hpram_rwds      
            );


    DVI_TX_Top
        u_DVI_TX_Top
            (
                .I_rst_n       (~dvi_reset      ),
                .I_serial_clk  (tmds_clk        ),
                .I_rgb_clk     (dvi_pix_clk     ),
                .I_rgb_vs      (dly1_vs         ),
                .I_rgb_hs      (dly1_hs         ),
                .I_rgb_de      (dly1_de         ),
                .I_rgb_r       (buf_de ? buf_data[9:2] : 8'h00),
                .I_rgb_g       (buf_de ? buf_data[9:2] : 8'h00),
                .I_rgb_b       (buf_de ? buf_data[9:2] : 8'hff),
                .O_tmds_clk_p  (tmds_clk_p      ),
                .O_tmds_clk_n  (tmds_clk_n      ),
                .O_tmds_data_p (tmds_data_p     ),
                .O_tmds_data_n (tmds_data_n     )
            );


    // -----------------------------
    //  LED
    // -----------------------------

    logic   [24:0]  counter;
    always_ff @(posedge mem_clk or posedge reset) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n = ~counter[23];
//    assign led_n = ov2640_vsync;//~counter[23];

endmodule


`default_nettype wire
