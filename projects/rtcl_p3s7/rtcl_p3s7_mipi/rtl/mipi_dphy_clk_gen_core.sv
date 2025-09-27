// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ps/1ps
`default_nettype none


module mipi_dphy_clk_gen_core
        (
            input   var logic   reset       ,
            input   var logic   clk_in1     ,

//          jelly3_axi4l_if.s   s_axi4l     ,

            input   var logic   pll_rst     ,
            input   var logic   pll_pwrdwn  ,

            output  var logic   clk_out1    ,
            output  var logic   clk_out2    ,
            output  var logic   clkfb_out   ,
            input   var logic   clkfb_in    ,

            output  var logic   locked      
        );


    logic   [6:0]   pll_daddr   ;
    logic           pll_dclk    ;
    logic           pll_den     ;
    logic   [15:0]  pll_di      ;
    logic   [15:0]  pll_do      ;
    logic           pll_drdy    ;
    logic           pll_dwe     ;

    PLLE2_ADV
            #(
                .BANDWIDTH          ("OPTIMIZED"        ),
                .COMPENSATION       ("ZHOLD"            ),
                .STARTUP_WAIT       ("FALSE"            ),
                .DIVCLK_DIVIDE      (1                  ),
                .CLKFBOUT_MULT      (20                 ),
                .CLKFBOUT_PHASE     (0.000              ),
                .CLKOUT0_DIVIDE     (5                  ),
                .CLKOUT0_PHASE      (0.000              ),
                .CLKOUT0_DUTY_CYCLE (0.500              ),
                .CLKOUT1_DIVIDE     (50                 ),
                .CLKOUT1_PHASE      (0.000              ),
                .CLKOUT1_DUTY_CYCLE (0.500              ),
                .CLKIN1_PERIOD      (20.000             )
            )
        u_plle2_adv
            (
                .CLKFBOUT            (clkfb_out         ),
                .CLKOUT0             (clk_out1          ),
                .CLKOUT1             (clk_out2          ),
                .CLKOUT2             (                  ),
                .CLKOUT3             (                  ),
                .CLKOUT4             (                  ),
                .CLKOUT5             (                  ),

                .CLKFBIN             (clkfb_in          ),
                .CLKIN1              (clk_in1           ),
                .CLKIN2              (1'b0              ),

                .CLKINSEL            (1'b1              ),

                .DADDR               (pll_daddr         ),
                .DCLK                (pll_dclk          ),
                .DEN                 (pll_den           ),
                .DI                  (pll_di            ),
                .DO                  (pll_do            ),
                .DRDY                (pll_drdy          ),
                .DWE                 (pll_dwe           ),

                .LOCKED              (locked            ),
                .PWRDWN              (1'b0              ),
                .RST                 (reset | pll_rst   )
            );


    assign pll_daddr = 7'h0 ;
    assign pll_dclk  = 1'b0 ;
    assign pll_den   = 1'b0 ;
    assign pll_di    = 16'h0;
    assign pll_dwe   = 1'b0 ;

    /*
    // AXI4-Lite
    assign pll_dclk = s_axi4l.aclk;

    logic   drp_busy    ;
    logic   drp_write   ;
    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rvalid <= 1'b0;
            drp_busy   <= 1'b0;
            drp_write  <= 1'b0;
            pll_den    <= 1'b0;
            pll_dwe    <= 1'b0;
            pll_daddr  <= 'x;
            pll_di     <= 'x;
        end
        else if ( s_axi4l.aclken ) begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end

            pll_den   <= 1'b0;
            pll_dwe   <= 1'b0;
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                drp_busy   <= 1'b1;
                drp_write  <= 1'b1;
                pll_den    <= 1'b1;
                pll_dwe    <= 1'b1;
                pll_daddr  <= s_axi4l.awaddr[7:1];
                pll_di     <= s_axi4l.wdata[15:0];
            end
            else if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                drp_busy   <= 1'b1;
                pll_den    <= 1'b1;
                pll_dwe    <= 1'b0;
                pll_daddr  <= s_axi4l.araddr[7:1];
            end

            if ( pll_drdy ) begin
                drp_busy   <= 1'b0;
                drp_write  <= 1'b0;
                if ( drp_write ) begin
                    s_axi4l.bvalid <= 1'b1;
                end
                else begin
                    s_axi4l.rdata  <= pll_do   ;
                    s_axi4l.rvalid <= 1'b1      ;
                end
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid  && ~s_axi4l.arvalid && ~drp_busy;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid && ~s_axi4l.arvalid && ~drp_busy;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = (~s_axi4l.rvalid || s_axi4l.rready) && ~drp_busy;
    assign s_axi4l.rresp   = '0;
    */

endmodule

`default_nettype wire

// end of file
