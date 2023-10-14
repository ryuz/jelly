
`timescale 1ns / 1ps
`default_nettype none

module tang_nano_9k_hdmi_sample
        (
            input   var logic           in_reset_n,
            input   var logic           in_clk,

            output  var logic           dvi_tx_clk_p,
            output  var logic           dvi_tx_clk_n,
            output  var logic   [2:0]   dvi_tx_data_p,
            output  var logic   [2:0]   dvi_tx_data_n,

            input   var logic   [0:0]   push_sw_n,
            output  var logic   [4:0]   led_n
        );

    // PLL
    logic   clk_x5;
    logic   lock;
    clkgen_pll
        u_clkgen_pll
            (
                .clk_in     (in_clk         ),
                .clk_out    (clk_x5         ),
                .lock       (lock           )
            );

    // CLKDIV
    logic   clk;
    clkgen_clkdiv
        u_clkgen_clkdiv
            (
                .reset_n    (in_reset_n     ),
                .clk_in     (clk_x5         ),
                .clk_out    (clk            )
            );

    // reset sync
    logic   reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1),
                .OUT_LOW_ACTIVE     (0),
                .INPUT_REGS         (2)
            )
        u_reset
            (
                .clk                (clk                ),
                .in_reset           (in_reset_n & lock  ),   // asyncrnous reset
                .out_reset          (reset              )    // syncrnous reset
            );


    // generate video sync 
    logic                           syncgen_vsync;
    logic                           syncgen_hsync;
    logic                           syncgen_de;
    jelly_vsync_generator_core
            #(
                .V_COUNTER_WIDTH    (10 ),
                .H_COUNTER_WIDTH    (10 )
            )
        u_vsync_generator_core
            (
                .reset              (reset  ),
                .clk                (clk    ),
                
                .ctl_enable         (1'b1   ),
                .ctl_busy           (       ),
                
                .param_htotal       (10'(96 + 16 + 640 + 48 )),
                .param_hdisp_start  (10'(96 + 16            )),
                .param_hdisp_end    (10'(96 + 16 + 640      )),
                .param_hsync_start  (10'(0                  )),
                .param_hsync_end    (10'(96                 )),
                .param_hsync_pol    (1'b0                    ), // 0:n 1:p
                .param_vtotal       (10'(2 + 10 + 480 + 33  )),
                .param_vdisp_start  (10'(2 + 10             )),
                .param_vdisp_end    (10'(2 + 10 + 480       )),
                .param_vsync_start  (10'(0                  )),
                .param_vsync_end    (10'(2                  )),
                .param_vsync_pol    (1'b0                    ), // 0:n 1:p
                
                .out_vsync          (syncgen_vsync  ),
                .out_hsync          (syncgen_hsync  ),
                .out_de             (syncgen_de     )
        );


    // 適当にパターンを作る
    logic           prev_de;
    logic   [10:0]  syncgen_x;
    logic   [10:0]  syncgen_y;
    always_ff @(posedge clk) begin
        prev_de <= syncgen_de;
        if ( syncgen_vsync == 1'b0 ) begin
            syncgen_y <= 0;
        end
        else if ( {prev_de, syncgen_de} == 2'b10 ) begin
            syncgen_y <= syncgen_y + 1;
        end

        if ( syncgen_hsync == 1'b0 ) begin
            syncgen_x <= 0;
        end
        else if ( syncgen_de ) begin
            syncgen_x <= syncgen_x + 1;
        end
    end
    
//    logic   [7:0]   xy;
//    assign xy  = 8'(syncgen_x + syncgen_y);
//    logic   [23:0]  syncgen_rgb;
//    assign syncgen_rgb = {xy, syncgen_y[7:0], syncgen_x[7:0]};



    logic               draw_vsync;
    logic               draw_hsync;
    logic               draw_de;
    logic   [2:0][7:0]  draw_rgb;

    draw_video
            #(
                .X_WIDTH    (11),
                .Y_WIDTH    (11)
            )
        i_draw_video
            (
                .reset,
                .clk,

                .push_sw    (~push_sw_n[0]),

                .in_vsync   (syncgen_vsync),
                .in_hsync   (syncgen_hsync),
                .in_de      (syncgen_de),
                .in_x       (syncgen_x),
                .in_y       (syncgen_y),

                .out_vsync  (draw_vsync),
                .out_hsync  (draw_hsync),
                .out_de     (draw_de),
                .out_rgb    (draw_rgb)
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
    logic   [26:0]  counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    assign led_n = ~counter[26:22];

endmodule

`default_nettype wire
