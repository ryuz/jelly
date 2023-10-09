
`default_nettype none

module tang_nano_9k_hdmi_sample
        (
            input   var logic           in_reset_n,
            input   var logic           in_clk,

            output  var logic           dvi_tx_clk_p,
            output  var logic           dvi_tx_clk_n,
            output  var logic   [2:0]   dvi_tx_data_p,
            output  var logic   [2:0]   dvi_tx_data_n,

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



    // timing gen
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

    logic           prev_hsync;
    logic   [11:0]   x;
    logic   [11:0]   y;
    always_ff @(posedge clk) begin
        prev_hsync <= syncgen_hsync;
        if ( syncgen_vsync == 1'b0 ) begin
            y <= 0;
        end
        else if ( {prev_hsync, syncgen_hsync} == 2'b01 ) begin
            y <= y + 1;
        end

        if ( syncgen_hsync == 1'b0 ) begin
            x <= 0;
        end
        else if ( syncgen_de ) begin
            x <= x + 1;
        end
    end

    // DVI TX
    wire    [7:0]   xy = x + y;
    dvi_tx
        u_dvi_tx
            (
                .reset          (reset  ),
                .clk            (clk    ),
                .clk_x5         (clk_x5 ),

                .in_vsync       (syncgen_vsync),
                .in_hsync       (syncgen_hsync),
                .in_de          (syncgen_de),
                .in_data        ({xy, y[7:0], x[7:0]}),
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
