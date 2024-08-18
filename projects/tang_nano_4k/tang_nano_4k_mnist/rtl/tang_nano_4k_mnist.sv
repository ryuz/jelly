
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

    

    // -----------------------------
    //  OV2640 カメラ設定
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
    //  縮小＆二値化
    // -----------------------------

    logic          prev_href;
    logic   [9:0]  cam_x;
    logic   [8:0]  cam_y;
    always_ff @(posedge ov2640_pixclk ) begin
        prev_href <= ov2640_href;

        if ( ~ov2640_href ) begin
            cam_x <= 0;
        end
        else begin
            cam_x <= cam_x + 1;
        end

        if ( ~ov2640_vsync ) begin
            cam_y <= 0;
        end
        else begin
            if ( {prev_href, ov2640_href} == 2'b01 ) begin
                cam_y <= cam_y + 1;
            end
        end
    end

    logic   [27:0][27:0]    bin_shr;
    logic   [27:0][27:0]    bin_img;
    always_ff @(posedge ov2640_pixclk) begin
        // 間引いてシフトレジスタにサンプリング
        if ( ov2640_href ) begin
            if ( cam_x[9:4] < 28 && cam_y[8:4] < 28 && cam_x[3:0] == 0 && cam_y[3:0] == 0 ) begin
                bin_shr <= (28*28)'({ov2640_pixdata < 512, bin_shr} >> 1);
            end
        end

        // ブランキングでラッチ 
        if ( ~ov2640_vsync ) begin
            bin_img <= bin_shr;
        end
    end


    // -----------------------------
    //  LUT-Network 画像認識
    // -----------------------------

    logic   [9:0]       mnist_class;
    MnistLutSimple
            #(
                .USE_REG        (0      ),
                .USER_WIDTH     (0      ),
                .DEVICE         ("RTL"  )
            )
        u_MnistLutSimple
            (
                .reset          (reset          ),
                .clk            (ov2640_pixclk  ),
                .cke            (1'b1           ),
                
                .in_user        ('0             ),
                .in_data        (bin_img        ),
                .in_valid       (1'b1           ),

                .out_user       (               ),
                .out_data       (mnist_class    ),
                .out_valid      (               )
            );


    // -----------------------------
    //  DVI同期信号生成
    // -----------------------------

    logic   syn_re;
    logic   syn_de;
    logic   syn_hs;
    logic   syn_vs;
    syn_gen
        u_syn_gen
            (
                .I_pxl_clk  (dvi_pix_clk    ),
                .I_rst_n    (~dvi_reset     ),   
                .I_h_total  (16'd1650       ), 
                .I_h_sync   (16'd40         ),
                .I_h_bporch (16'd220        ), 
                .I_h_res    (16'd1280       ), 
                .I_v_total  (16'd750        ),  
                .I_v_sync   (16'd5          ),  
                .I_v_bporch (16'd20         ),   
                .I_v_res    (16'd720        ),  
                .I_rd_hres  (16'd640        ),
                .I_rd_vres  (16'd480        ),
                .I_hs_pol   (1'b1           ),
                .I_vs_pol   (1'b1           ),
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


    // -----------------------------
    //  フレームバッファ
    // -----------------------------

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

    // -----------------------------
    //  表示画像オーバーレイ
    // -----------------------------

    logic           prev_de;
    logic   [10:0]  dvi_x;
    logic   [9:0]   dvi_y;
    always_ff @(posedge dvi_pix_clk ) begin
        prev_de <= dly1_de;

        if ( ~dly1_de ) begin
            dvi_x <= 0;
        end
        else begin
            dvi_x <= dvi_x + 1;
        end

        if ( dly1_vs ) begin
            dvi_y <= 0;
        end
        else begin
            if ( {prev_de, dly1_de} == 2'b10 ) begin
                dvi_y <= dvi_y + 1;
            end
        end
    end

    localparam int  BIN_X = 50;
    localparam int  BIN_Y = 1;
    logic  bin_en;
    logic  bin_view;
    always_ff @(posedge dvi_pix_clk ) begin
        if ( dvi_x[10:4] >= BIN_X && dvi_x[10:4] < BIN_X+28 
                && dvi_y[9:4] >= BIN_Y && dvi_y[9:4]  < BIN_Y+28 ) begin
            bin_en   <= 1;
            bin_view <= bin_img[dvi_y[9:4]-BIN_Y][dvi_x[10:4]-BIN_X];
        end
        else begin
            bin_en   <= 0;
            bin_view <= 0;
        end
    end

    localparam int  MNIST_X = 1;
    localparam int  MNIST_Y = 18;
    logic  mnist_en;
    logic  mnist_view;
    always_ff @(posedge dvi_pix_clk ) begin
        if ( dvi_x[10:5] >= MNIST_X && dvi_x[10:5] < MNIST_X+10 
                && dvi_y[9:5] >= MNIST_Y && dvi_y[9:5] < MNIST_Y+1 ) begin
            mnist_en   <= 1;
            mnist_view <= mnist_class[dvi_x[10:5]-MNIST_X];
        end
        else begin
            mnist_en   <= 0;
            mnist_view <= 0;
        end
    end


    // -----------------------------
    //  DVI出力
    // -----------------------------

    DVI_TX_Top
        u_DVI_TX_Top
            (
                .I_rst_n       (~dvi_reset      ),
                .I_serial_clk  (tmds_clk        ),
                .I_rgb_clk     (dvi_pix_clk     ),
                .I_rgb_vs      (dly1_vs         ),
                .I_rgb_hs      (dly1_hs         ),
                .I_rgb_de      (dly1_de         ),
                .I_rgb_r       (buf_de ? buf_data[9:2] : bin_en ? {8{bin_view}} : mnist_en ? {8{mnist_view}} : dvi_x),
                .I_rgb_g       (buf_de ? buf_data[9:2] : bin_en ? {8{bin_view}} : mnist_en ? {8{mnist_view}} : dvi_y),
                .I_rgb_b       (buf_de ? buf_data[9:2] : bin_en ? {8{bin_view}} : mnist_en ? {8{mnist_view}} : 8'hff),
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
//    assign led_n = ^mnist_class;
//    assign led_n = ov2640_vsync;

endmodule


`default_nettype wire
