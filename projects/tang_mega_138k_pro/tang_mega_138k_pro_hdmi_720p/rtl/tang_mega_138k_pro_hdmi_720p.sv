
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_hdmi_720p
        (
            input   var logic           in_reset        ,
            input   var logic           in_clk          ,

            output  var logic           dvi_tx_clk_p    ,
            output  var logic           dvi_tx_clk_n    ,
            output  var logic   [2:0]   dvi_tx_data_p   ,
            output  var logic   [2:0]   dvi_tx_data_n   ,

            input   var logic   [3:0]   push_sw_n       ,
            output  var logic   [5:0]   led_n           
        );

    localparam  int     DVI_H_BITS = 11     ;
    localparam  int     DVI_V_BITS = 10     ;
    localparam  int     DVI_WIDTH  = 1280   ;
    localparam  int     DVI_HEIGHT = 720    ;

    // PLL
    logic   clk     ;
    logic   clk_x5  ;
    logic   lock    ;
    Gowin_PLL
        u_pll
            (
                .clkin              (in_clk             ),
                .clkout0            (clk                ),
                .clkout1            (clk_x5             ),
                .lock               (lock               )
            );
    
    // reset sync
    logic   reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                  ),
                .OUT_LOW_ACTIVE     (0                  ),
                .INPUT_REGS         (2                  )
            )
        u_reset
            (
                .clk                (clk                ),
                .in_reset           (~in_reset & lock   ),   // asyncrnous reset
                .out_reset          (reset              )    // syncrnous reset
            );


    // generate video sync
    logic                           syncgen_vsync;
    logic                           syncgen_hsync;
    logic                           syncgen_de;
    jelly_vsync_generator_core
            #(
                .H_COUNTER_WIDTH    (DVI_H_BITS     ),
                .V_COUNTER_WIDTH    (DVI_V_BITS     )
            )
        u_vsync_generator_core
            (
                .reset              (reset          ),
                .clk                (clk            ),
                
                .ctl_enable         (1'b1           ),
                .ctl_busy           (               ),
                
                .param_htotal       (11'd1650       ),
                .param_hdisp_start  (11'd0          ),
                .param_hdisp_end    (11'd1280       ),
                .param_hsync_start  (11'd1390       ),
                .param_hsync_end    (11'd1430       ),
                .param_hsync_pol    (1'b1           ),
                .param_vtotal       (10'd750        ),
                .param_vdisp_start  (10'd0          ),
                .param_vdisp_end    (10'd720        ),
                .param_vsync_start  (10'd725        ),
                .param_vsync_end    (10'd730        ),
                .param_vsync_pol    (1'b1           ),
                
                .out_vsync          (syncgen_vsync  ),
                .out_hsync          (syncgen_hsync  ),
                .out_de             (syncgen_de     )
        );


    // 適当にパターンを作る
    logic                       prev_de;
    logic   [DVI_H_BITS-1:0]    syncgen_x;
    logic   [DVI_V_BITS-1:0]    syncgen_y;
    always_ff @(posedge clk) begin
        prev_de <= syncgen_de;
        if ( syncgen_vsync == 1'b1 ) begin
            syncgen_y <= 0;
        end
        else if ( {prev_de, syncgen_de} == 2'b10 ) begin
            syncgen_y <= syncgen_y + 1;
        end

        if ( syncgen_hsync == 1'b1 ) begin
            syncgen_x <= 0;
        end
        else if ( syncgen_de ) begin
            syncgen_x <= syncgen_x + 1;
        end
    end
    
    // draw
    logic               draw_vsync;
    logic               draw_hsync;
    logic               draw_de;
    logic   [2:0][7:0]  draw_rgb;

    draw_video
            #(
                .X_SIZE     (DVI_WIDTH  ),
                .Y_SIZE     (DVI_HEIGHT ),
                .X_BITS     (DVI_H_BITS ),
                .Y_BITS     (DVI_V_BITS )
            )
        u_draw_video
            (
                .reset,
                .clk,

                .push_sw    (~{push_sw_n[3], push_sw_n[0]}),

                .in_vsync   (syncgen_vsync  ),
                .in_hsync   (syncgen_hsync  ),
                .in_de      (syncgen_de     ),
                .in_x       (syncgen_x      ),
                .in_y       (syncgen_y      ),

                .out_vsync  (draw_vsync     ),
                .out_hsync  (draw_hsync     ),
                .out_de     (draw_de        ),
                .out_rgb    (draw_rgb       )
            );


    // DVI TX
    dvi_tx
        u_dvi_tx
            (
                .reset          (reset  ),
                .clk            (clk    ),
                .clk_x5         (clk_x5 ),

                .in_vsync       (draw_vsync),
                .in_hsync       (draw_hsync),
                .in_de          (draw_de),
                .in_data        (draw_rgb),
                .in_ctl         ('0),

                .out_clk_p      (dvi_tx_clk_p),
                .out_clk_n      (dvi_tx_clk_n),
                .out_data_p     (dvi_tx_data_p),
                .out_data_n     (dvi_tx_data_n)
            );
    

    // LED
    logic   [24:0]  counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n[0] = ~counter[24];
    assign led_n[1] = push_sw_n[0];
    assign led_n[2] = push_sw_n[3];
    assign led_n[4] = ~in_reset;
    assign led_n[3] = ~lock;
    assign led_n[5] = ~reset;

endmodule

`default_nettype wire
